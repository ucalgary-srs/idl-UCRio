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

pro __ucrio_readfile_norstar, $
  filename, $
  data, $
  metadata, $
  timestamp_list, $
  start_dt = start_dt, $
  end_dt = end_dt, $
  verbose = verbose, $
  no_metadata = no_metadata
  compile_opt hidden

  NORSTAR_RIOMETER_3_LETTER_SITE_CODES = hash('chur', ['chu'], $
    'cont', ['con'], $
    'daws', ['daw'], $
    'arvi', ['esk'], $
    'fsim', ['sim'], $
    'fsmi', ['smi'], $
    'gill', ['gil'], $
    'isll', ['isl'], $
    'mcmu', ['mcm'], $
    'pina', ['pin'], $
    'rabb', ['rab'], $
    'rank', ['ran'], $
    'talo', ['tal'])

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
      start_long = ulong(start_yy + start_mm + start_dd)
    endif
    if keyword_set(end_dt) then begin
      end_yy = strmid(end_dt, 0, 4)
      end_mm = strmid(end_dt, 5, 2)
      end_dd = strmid(end_dt, 8, 2)
      end_hr = strmid(end_dt, 11, 2)
      end_mn = strmid(end_dt, 14, 2)
      end_long = ulong(end_yy + end_mm + end_dd)
    endif

    f_indices_to_read = []
    foreach f, filenames, file_idx do begin
      long_d = ulong((strsplit((strsplit(f, path_sep(), /extract))[-1], '_', /extract))[-2])
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

  foreach f, filenames do begin
    if (verbose gt 0) then print, '[ucrio_read] Reading file: ' + f

    ; set up arrays for this file's data
    file_timestamp = []
    file_raw_signal = []
    file_absorption = []
    file_metadata = hash()

    f_basename = (strsplit(f, path_sep(), /extract))[-1]

    ; determine number of expected columns
    ;
    ; NOTE: We use the filename here to tell us if it's a k0 or k2
    ; file, since we cannot assume the dataset name will be supplied
    ; to the parent functions.
    if strmatch(f_basename, '*_k0_*') or strmatch(f_basename, '*v0.txt') then begin
      file_type = 'k0'
    endif else if strmatch(f_basename, '*_k2_*') or strmatch(f_basename, '*v1a.txt') then begin
      file_type = 'k2'
    endif else begin
      if (verbose gt 0) then begin
        print, '[ucrio_read] Error: Could not read file. Unknown file type for file ' + f
      endif
      continue
    endelse

    ; extract start and end times of the file
    ymd = (strsplit(f_basename, '_', /extract))[-2]
    if strlen(ymd) ne 8 then begin
      print, '[ucrio_read] Error: Could not read file. Could not parse date from filename for file ' + f
    endif

    ; If start_dt or end_dt were passed, we need to grab julian versions of them
    if keyword_set(start_dt) or keyword_set(end_dt) then begin
      if keyword_set(start_dt) then begin
        start_yy = strmid(start_dt, 0, 4)
        start_mm = strmid(start_dt, 5, 2)
        start_dd = strmid(start_dt, 8, 2)
        start_hr = strmid(start_dt, 11, 2)
        start_mn = strmid(start_dt, 14, 2)
        start_sc = strmid(start_dt, 17, 2)
        start_juldt = julday(fix(start_mm), fix(start_dd), fix(start_yy), fix(start_hr), fix(start_mn), fix(start_sc))
      endif
      if keyword_set(end_dt) then begin
        end_yy = strmid(end_dt, 0, 4)
        end_mm = strmid(end_dt, 5, 2)
        end_dd = strmid(end_dt, 8, 2)
        end_hr = strmid(end_dt, 11, 2)
        end_mn = strmid(end_dt, 14, 2)
        end_sc = strmid(end_dt, 17, 2)
        end_juldt = julday(fix(end_mm), fix(end_dd), fix(end_yy), fix(end_hr), fix(end_mn), fix(end_sc))
      endif
    end

    ; Read the text file
    is_err = 0
    line = ''
    no_more_meta = 0
    openr, lun, f, /get_lun
    while not eof(lun) do begin
      ; read line by line
      readf, lun, line

      if strmid(line, 0, 1) ne '#' then begin
        ; not a comment, split line by column
        line_split = strsplit(line, ' ', /extract)

        if (file_type eq 'k0') then begin
          line_date = line_split[0]
          line_time = line_split[1]
          line_raw_signal = float(line_split[2])
        endif else begin
          line_date = line_split[0]
          line_time = line_split[1]
          line_absorption = float(line_split[2])
          line_raw_signal = float(line_split[3])
        endelse

        ; Don't add UT24 records, those are a result of a bug
        ; and should not be in the file
        if strmid(line_time, 0, 2) eq '24' then continue

        ; Some files have ** in timestamps, indicated incorrect print formatting
        ; in file creation. If this is the case, we skip reading the entire file
        ; as is done in PyAuroraX
        if strmatch(line_time, '*\**') then begin
          print, '[ucrio_read] Error: Could not process timestamps for file ' + f
          is_err = 1
          break
        endif

        ; Format this line's timestamp properly
        if fix(strmid(line_date, 6, 2)) lt 89 then begin
          line_ts = '20' + strmid(line_date, 6, 2) + '-' + strmid(line_date, 3, 2) + '-' + strmid(line_date, 0, 2) + ' ' + $
            strmid(line_time, 0, 2) + ':' + strmid(line_time, 3, 2) + ':' + strmid(line_time, 6, 2) + ' utc'
        endif else begin
          line_ts = '19' + strmid(line_date, 6, 2) + '-' + strmid(line_date, 3, 2) + '-' + strmid(line_date, 0, 2) + ' ' + $
            strmid(line_time, 0, 2) + ':' + strmid(line_time, 3, 2) + ':' + strmid(line_time, 6, 2) + ' utc'
        endelse

        ; Don't add records that are outside of the requested timerange for reading
        if keyword_set(start_dt) or keyword_set(end_dt) then begin
          this_juldt = julday(fix(strmid(line_ts, 5, 2)), fix(strmid(line_ts, 8, 2)), fix(strmid(line_ts, 0, 4)), $
            fix(strmid(line_ts, 11, 2)), fix(strmid(line_ts, 14, 2)), fix(strmid(line_ts, 17, 2)))

          if (keyword_set(start_dt) and this_juldt lt start_juldt) then continue
          if (keyword_set(end_dt) and this_juldt gt end_juldt) then continue
        endif

        ; If data read is succesful, add to arrays
        if (file_type eq 'k0') then begin
          file_timestamp = [file_timestamp, line_ts]
          file_raw_signal = [file_raw_signal, line_raw_signal]
        endif else if (file_type eq 'k2') then begin
          file_timestamp = [file_timestamp, line_ts]
          file_raw_signal = [file_raw_signal, line_raw_signal]
          file_absorption = [file_absorption, line_absorption]
        endif
      endif else if strmid(line, 0, 1) eq '#' then begin
        if (~keyword_set(no_metadata)) then begin
          if (no_more_meta eq 1) then continue

          ; line is a comment, parse metadata

          found_site_uid = !null

          ; remove # from line
          line = strmid(line, 1)

          ; end of metadata, bail out
          if strmatch(line, '*------------*') then begin
            no_more_meta = 1
            continue
          endif

          ; split the line based
          ;
          ; NOTE: some lines are differently formatted, so we
          ; need a few special cases to handle them
          if strmatch(line, '*Version*') then begin
            ; version line
            file_metadata['version'] = strtrim(line, 2)
          endif else if strmatch(line, '*----*') then begin
            ; summary line
            file_metadata['summary'] = strtrim(line, 2)
          endif else begin
            ; find first colon
            sep = strpos(line, ':')

            if sep eq -1 then begin
              ; trim and return full line
              line_split = [strtrim(line, 2)]
            endif else begin
              ; text before and after first colon
              first_str = strtrim(strmid(line, 0, sep), 2)
              second_str = strtrim(strmid(line, sep + 1), 2)
              line_split = [first_str, second_str]
            endelse

            ; parse processing date
            if strmatch(strlowcase(line), '*processing_date*') then begin
              file_metadata['processing_date'] = (strsplit(line_split[1], /extract))[1]
            endif else if (strmatch(strlowcase(line), '*site unique id*')) then begin
              ; skip this line since it is not consistent in the metadata, so
              ; we will derive it from the filename and insert it after this loop
              found_site_uid = strlowcase(line_split[1])
              continue
            endif else begin
              file_metadata[strjoin(strsplit(strlowcase(line_split[0]), ' ', /extract), '_')] = line_split[1]
            endelse
          endelse
        endif
      endif
    endwhile
    free_lun, lun

    if isa(found_site_uid) then begin
      file_metadata['site_unique_id'] = found_site_uid
    endif else begin
      ; need to determine site uid
      if strmid(f_basename, 3, 1) eq '_' then begin
        ; need to convert three letter id to correct site_uid
        idx = where(NORSTAR_RIOMETER_3_LETTER_SITE_CODES.values() eq strmid(f_basename, 0, 3), /null)
        if (idx ne !null) then begin
          file_metadata['site_unique_id'] = (NORSTAR_RIOMETER_3_LETTER_SITE_CODES.keys())[idx]
        endif
      endif else begin
        ; four letter site code parsing from filename
        idx = strpos(f_basename, 'rio-')
        if (idx ne -1) then begin
          file_metadata['site_unique_id'] = strlowcase(strmid(f_basename, idx + 4, 4))
        endif
      endelse
    endelse

    if (where(file_metadata.keys() eq 'site_unique_id', /null) eq !null) then begin
      if (verbose ge 0) then print, '[ucrio_read] Warning: Unable to determine "site_unique_id" field in file ' + f
      file_metadata['site_unique_id'] = 'unknown'
    endif

    ; If there was a timestamp error, skip the whole file
    if (is_err eq 1) then continue

    ; Append all to lists
    master_timestamp.add, file_timestamp
    master_metadata.add, file_metadata
    if (file_type eq 'k2') then begin
      master_data.add, {raw_signal: file_raw_signal, absorption: file_absorption}
    endif else if (file_type eq 'k0') then begin
      master_data.add, {raw_signal: file_raw_signal, absorption: !values.f_nan}
    endif
  endforeach

  ; Assign to global vars
  data = master_data
  metadata = master_metadata
  timestamp_list = master_timestamp
end
