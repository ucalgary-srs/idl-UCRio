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

pro ucrio_example_download_data
  ; download one day of raw NORSTAR riometer data
  ;
  ; using the ucrio_list_datasets() function, we figured out that
  ; the dataset names we want to use
  d = ucrio_download('NORSTAR_RIOMETER_K2_TXT', '2017-11-09T00:00:00', '2017-11-09T23:59:59', site_uid = 'pina')
  help, d
  print, ''
  
  ; download with no output
  d = ucrio_download('NORSTAR_RIOMETER_K0_TXT', '2017-11-09T00:00:00', '2017-11-09T23:59:59', site_uid = 'pina', /quiet)
  print, ''

  ; download one day of data from all sites
  d = ucrio_download('NORSTAR_RIOMETER_K0_TXT', '2017-11-09T00:00:00', '2017-11-09T23:59:59')
  print, ''

  ; download force redownload of data, even if it exists locally already
  d = ucrio_download('NORSTAR_RIOMETER_K0_TXT', '2017-11-09T00:00:00', '2017-11-09T23:59:59', site_uid = 'pina', /overwrite)
  print, ''
end
