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

;+
; :Description:
;       Read data files that were downloaded from the UCalgary Open Data Platform.
;
; :Parameters:
;       dataset: in, required, Struct
;         struct for the dataset that is being read in (retrieved from ucrio_list_dataset() function)
;       file_list: in, required, String or Array
;         list of files on the local computer to read in (can also be a single filename string)
;
; :Keywords:
;       start_dt: in, optional, String
;         string giving the start timestamp to read data for (format: 'yyyy-mm-ddTHH:MM:SS')
;       end_dt: in, optional, String
;         string giving the end timestamp to read data for (format: 'yyyy-mm-ddTHH:MM:SS')
;       first_record: in, optional, Boolean
;         only read the first record/frame/image in each file
;       no_metadata: in, optional, Boolean
;         exclude reading of metadata
;       quiet: in, optional, Boolean
;         read data silently, no print messages will be shown
;
; :Returns:
;       Struct
;
; :Examples:
;       download_obj = aurorax_ucalgary_download('THEMIS_ASI_RAW', '2022-01-01T06:00:00', '2022-01-01T06:59:59', site_uid = 'gill')
;       data = aurorax_ucalgary_read(download_obj.dataset, download_obj.filenames)
;       help,data
;
;       data = aurorax_ucalgary_read(download_obj.dataset, download_obj.filenames, start_dt = '2022-01-01T06:13:00', end_dt = '2022-01-01T06:40:00')
;       help, data
;+
function ucrio_read, dataset, file_list, start_dt = start_dt, end_dt = end_dt, first_record = first_record, no_metadata = no_metadata, quiet = quiet
  ; init
  timestamp_list = list()
  metadata_list = list()
  calibrated_data = ptr_new()

  ; set keyword flags
  quiet_flag = 0
  if keyword_set(quiet) then quiet_flag = 1

  ; check if this dataset is supported for reading
  supported = ucrio_is_read_supported(dataset.name)

  ; check that start_dt/end_dt are valid if they are passed
  if keyword_set(start_dt) then begin
    ; ensure string type
    if ~isa(start_dt, /string) then begin
      print, '[ucrio_read] Start timestamp of type ' + typename(start_dt) + ' is invalid, expected string'
      return, !null
    endif else if ~isa(end_dt, /string) then begin
      print, '[ucrio_read] End timestamp of type ' + typename(end_dt) + ' is invalid, expected string'
      return, !null
    endif

    ; ensure string format
    if strlen(start_dt) eq 16 then start_dt += ':00'
    if strlen(end_dt) eq 16 then end_dt += ':00'
    if strlen(start_dt) ne strlen(end_dt) then begin
      print, '[ucrio_read] Start and end timestamp must have the same format'
      print, strlen(start_dt)
      print, strlen(end_dt)
      return, !null
    endif
    if strlen(start_dt) ne 19 or strmid(start_dt, 4, 1) ne '-' or strmid(start_dt, 7, 1) ne '-' or $
      strmid(start_dt, 10, 1) ne 'T' or strmid(start_dt, 13, 1) ne ':' or strmid(start_dt, 16, 1) ne ':' then begin
      print, '[ucrio_read] Start timestamp must have format "yyyy-mm-ddTHH:MM" or "yyyy-mm-ddTHH:MM:SS", received' + start_dt
      return, !null
    endif
    if strlen(end_dt) ne 19 or strmid(end_dt, 4, 1) ne '-' or strmid(end_dt, 7, 1) ne '-' or $
      strmid(end_dt, 10, 1) ne 'T' or strmid(end_dt, 13, 1) ne ':' or strmid(end_dt, 16, 1) ne ':' then begin
      print, '[ucrio_read] End timestamp must have format "yyyy-mm-ddTHH:MM" or "yyyy-mm-ddTHH:MM:SS", received' + end_dt
      return, !null
    endif
  endif

  if (supported eq 0) then begin
    print, '[ucrio_read] Dataset ''' + dataset.name + ''' not supported for reading'
    return, !null
  endif

  ; determine read function to use
  norstar_readfile_datasets = list( $
    'NORSTAR_RIOMETER_K0_TXT', $
    'NORSTAR_RIOMETER_K2_TXT')
  hsr_readfile_datasets = list( $
    'SWAN_HSR_K0_H5')
  if (isa(norstar_readfile_datasets.where(dataset.name)) eq 1) then begin
    ; use norstar readfile
    read_function = 'norstar'
  endif else if (isa(hsr_readfile_datasets.where(dataset.name)) eq 1) then begin
    ; use HSR readfile
    read_function = 'hsr'
  endif

  ; read the data
  if (read_function eq 'norstar') then begin
    if (keyword_set(first_record) eq 1) then print, '[ucrio_read] Warning: keyword first_record is not accepted for NORSTAR riometer data, and will have no effect'
    if (quiet_flag eq 0) then begin
      __ucrio_readfile_norstar, file_list, data, meta, timestamp_list, start_dt = start_dt, end_dt = end_dt, no_metadata = no_metadata, /verbose
    endif else begin
      __ucrio_readfile_norstar, file_list, data, meta, timestamp_list, start_dt = start_dt, end_dt = end_dt, no_metadata = no_metadata, verbose=-1
    endelse
  endif else if (read_function eq 'hsr') then begin
    if (keyword_set(first_record) eq 1) then print, '[ucrio_read] Warning: keyword first_record is not accepted for SWAN HSR data, and will have no effect'
    if (quiet_flag eq 0) then begin
      __ucrio_readfile_hsr, file_list, data, meta, timestamp_list, start_dt = start_dt, end_dt = end_dt, no_metadata = no_metadata, /verbose
    endif else begin
      __ucrio_readfile_hsr, file_list, data, meta, timestamp_list, start_dt = start_dt, end_dt = end_dt, no_metadata = no_metadata, verbose=-1
    endelse
  endif
  
  if n_elements(data) eq 0 then return, !null
  
  ; put data into a struct
  return, {data: data, timestamp: timestamp_list, metadata: meta, dataset: dataset}
end
