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

pro ucrio_example_read_data
  ; download one day of NORSTAR Riometer data
  d = ucrio_download('NORSTAR_RIOMETER_K2_TXT', '2017-11-09T00:00:00', '2017-11-09T23:59:59', site_uid = 'pina')

  ; set list of files to read
  ;
  ; NOTE: this is not necessary in practice, but we show here to illustrate where the filename information is in a
  ; download return variable
  f = d.filenames

  ; read the data
  data = ucrio_read(d.dataset, f)
  help, data

  ; read only some of the data using start_dt and end_dt
  data = ucrio_read(d.dataset, f, start_dt='2017-11-09T06:00:00', end_dt='2017-11-09T09:59:00')
  
  ; read the data quietly
  data = ucrio_read(d.dataset, f, /quiet)

end
