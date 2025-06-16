; -------------------------------------------------------------
; Copyright 2024 University of Calgary
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
; -------------------------------------------------------------

pro __ucrio_readfile_hsr, $
  filename, $
  data, $
  metadata, $
  timestamp_list, $
  start_dt = start_dt, $
  end_dt = end_dt, $
  verbose = verbose, $
  no_metadata = no_metadata, $
  compile_opt hidden
  
  if not isa(verbose) then verbose = 1

  ; create local var for filenames
  filenames = filename

  ; Convert scalar filename to length 1 array so we can iterate regardless
  if isa(filenames, /scalar) then filenames = [filenames]

  ; If start_dt or end_dt were passed, we need to cut down the filenames accordingly
  if keyword_set(start_dt) or keyword_set(end_dt) then begin
    if keyword_set(start_dt) then begin
      start_yy = strmid(start_dt, 0, 4)
      start_mm = strmid(start_dt, 5, 2)
      start_dd = strmid(start_dt, 8, 2)
      start_hr = strmid(start_dt, 11, 2)
      start_mn = strmid(start_dt, 14, 2)
      start_sc = strmid(start_dt, 17, 2)
      start_long = ulong(start_yy+start_mm+start_dd)
      start_juldt = julday(start_mm, start_dd, start_yy, start_hr, start_mn, start_sc)
    endif
    if keyword_set(end_dt) then begin
      end_yy = strmid(end_dt, 0, 4)
      end_mm = strmid(end_dt, 5, 2)
      end_dd = strmid(end_dt, 8, 2)
      end_hr = strmid(end_dt, 11, 2)
      end_mn = strmid(end_dt, 14, 2)
      end_sc = strmid(end_dt, 17, 2)
      end_long = ulong(end_yy+end_mm+end_dd)
      end_juldt = julday(end_mm, end_dd, end_yy, end_hr, end_mn, end_sc)
    endif

    f_indices_to_read = []
    foreach f, filenames, file_idx do begin
      long_d = ulong((strsplit((strsplit(f, path_sep(), /extract))[-1], '_', /extract))[0])
      if keyword_set(start_dt) and long_d lt start_long then continue
      if keyword_set(end_dt) and long_d gt end_long then continue
      f_indices_to_read = [f_indices_to_read, file_idx]
    endforeach

    ; Check that the start/end time range actually corresponds to the files passed in
    if f_indices_to_read eq !null then begin
      print, '[ucrio_read] Error - range start_dt, end_dt does not correspond to any of the input files'
      return
    endif

    ; if everything worked properly we can now slice out the filenamess we actually want to read
    filenames = filenames[f_indices_to_read[0] : f_indices_to_read[-1]]
  end

  filenames = filenames.toarray()

  n_files = n_elements(filenames)
  if (n_files gt 1) then filenames = filenames[sort(filenames)]

  ; Setting up master lists to hold data for multi-file reading
  master_timestamp = list()
  master_data = list()
  master_metadata = list()

  frames_read_counter = 0ul
  break_after_first = 0
  n_files_outside_timerange = 0ul
  foreach f, filenames, file_num do begin
    if (verbose gt 0) then print, '[ucrio_read] Reading file: ' + f
    
    f_basename = (strsplit(f, path_sep(), /extract))[-1]
    
    ; Open h5 file
    file_id = h5f_open(f)

    ; Get data group ID and ensure it's not empty
    data_group_id = h5g_open(file_id, 'data')
    if h5g_get_nmembers(file_id, 'data') eq 0 then begin
      print, "[ucrio_read] Error: empty data group found in file "+f
      continue
    endif
    
    ; Get dataset identifiers
    timestamp_dataset_id = h5d_open(data_group_id, 'timestamp')
    band_central_freq_id = h5d_open(data_group_id, 'band_central_frequency')
    band_passband_id = h5d_open(data_group_id, 'band_passband')
    raw_power_id = h5d_open(data_group_id, 'raw_power')
    
    ; NOTE: These are already in the metadata... need to check
    ; if there is any reason to read them in from data group
    ; 
;    ; Read central frequency and passband (String array)
;    band_central_freq = h5d_read(band_central_freq_id)
;    band_passband = h5d_read(band_passband_id)
    
    ; Read timestamps and strip off 'UTC'
    timestamps = strmid(h5d_read(timestamp_dataset_id),0,19)
    
    ; Read in raw power 
    raw_power = h5d_read(raw_power_id)
    
    ; Filter based on start and end date if requested
    if (keyword_set(start_dt) or keyword_set(end_dt)) then begin
      ; Convert timestamps to julian dates for comparison
      data_yy = fix(strmid(timestamps,0,4))
      data_mm = fix(strmid(timestamps,5,2))
      data_dd = fix(strmid(timestamps,8,2))
      data_hr = fix(strmid(timestamps,11,2))
      data_mn = fix(strmid(timestamps,14,2))
      data_sc = fix(strmid(timestamps,17,2))
      data_juldt = julday(data_mm, data_dd, data_yy, data_hr, data_mn, data_sc)
      
      ; Obtain indices corresponding to desired time range
      if (keyword_set(start_dt) and keyword_set(end_dt)) then begin
        ; start and end time supplied
        ts_idx = where(data_juldt ge start_juldt and data_juldt le end_juldt, /null)
      endif else if keyword_set(start_dt) then begin
        ; only start time supplied
        ts_idx = where(data_juldt ge start_juldt, /null)
      endif else if keyword_set(end_dt) then begin
        ; only end time supplied
        ts_idx = where(data_juldt le end_juldt, /null)
      endif

      if ts_idx eq !null then begin
        print, '[ucrio_read] Error - range start_dt, end_dt does not correspond to any of the input files'
        continue
      endif
      
      ; Cut down timestamp and data to requested range
      timestamps = timestamps[ts_idx]
      raw_power = raw_power[ts_idx]
      
    endif
    
    ; Reading in the file level metadata into a hash and then converting to IDL struct
    meta_group_id = h5g_open(file_id, 'metadata')
    file_meta_dataset_id = h5d_open(meta_group_id, 'file')
    n_file_meta_attributes = h5a_get_num_attrs(file_meta_dataset_id)

    ; Iterating through each attribute and adding to hash, then converting to struct
    file_metadata = hash()
    for i = 0, (n_file_meta_attributes - 1) do begin
      attribute_id = h5a_open_idx(file_meta_dataset_id, i)
      attribute_name = h5a_get_name(attribute_id)
      attribute = h5a_read(attribute_id)
      file_metadata[attribute_name] = attribute
    endfor
    
    ; Append all to lists
    master_timestamp.add, timestamps
    master_metadata.add, file_metadata
    if (strmatch(f_basename, '*k2*') eq 1) then begin
      master_data.add, {raw_power:raw_power, absorption:file_absorption}
    endif else if (strmatch(f_basename, '*k0*') eq 1) then begin
      master_data.add, {raw_power:raw_power, absorption:!values.f_nan}
    endif
    h5_close
  endforeach
  
  ; Assign to global vars
  data = master_data
  metadata = master_metadata
  timestamp_list = master_timestamp
  
end
