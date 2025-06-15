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

pro ucrio_example_datasets_and_observatories
  ; ------------------------
  ; Explore datasets
  ; ------------------------
  ;
  ; All data available is organized by unique 'dataset' identifier strings, similar to CDAWeb. For
  ; example, `NORSTAR_RIOMETER_K0_TXT` is the dataset name for the raw NORSTAR riometer data, one of
  ; the common datasets for that instrument array.
  ;
  ; There are a few functions to help explore the available datasets and information about them. There
  ; is `ucrio_list_datasets()` to retrieve any datasets matching optional filters, and
  ; `ucrio_get_dataset()` which retrieves a specific single dataset.
  ;
  ; You can also navigate to the Dataset Descriptions page (https://data.phys.ucalgary.ca/about_datasets)
  ; and navigate to a particular instrument page. There, you will find a listing of all available (and
  ; commonly utilized) datasets for an instrument, along with instrument location/field-of-view maps,
  ; and observatory locations.
  ;
  ; Each dataset has a few attributes. For example, DOI and citation information, data tree location, and
  ; provider.

  ; list datasets
  datasets = ucrio_list_datasets()
  print, 'Found ' + strcompress(fix(n_elements(datasets)), /remove_all) + ' datasets'

  ; show the first one
  help, datasets[0]
  print, ''

  ; list datasets with filter
  datasets = ucrio_list_datasets(name = 'norstar')
  print, 'Found ' + strcompress(fix(n_elements(datasets)), /remove_all) + ' datasets'
  help, datasets[0]
  print, ''

  ; get a specific dataset
  dataset = ucrio_get_dataset('SWAN_HSR_K0_H5')
  help, dataset
  print, ''

  ; ------------------------
  ; Explore observatories
  ; ------------------------
  ;
  ; A set of observatories are available for each instrument array. These observatories provide information
  ; about the sites where data was produced during the array operations. Each observatory object provides
  ; site code and full names, along with their geodetic latitude and longitude.
  ;
  ; You can use the `aurorax_list_observatories()` function to retrieve observatory information. To determine
  ; the valid 'instrument_array' values, please refer to the IDL-UCRio API reference, or utilize the integrated
  ; docs for the functions.

  ; list all observatories for NORSTAR Riometers
  observatories = ucrio_list_observatories('norstar_riometer')
  print, 'Found ' + strcompress(fix(n_elements(observatories)), /remove_all) + ' observatories part of the "norstar_riometer" instrument array'
  print, ''

  ; You can also filter using the UID parameter. This filter will find partial
  ; matches as well.
  obs_buff = ucrio_list_observatories('norstar_riometer', uid = 'talo')
  print, 'Retrieved and displaying the NORSTAR Riometer BUFF observatory'
  help, obs_buff[0]
  print, ''
end
