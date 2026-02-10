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

; init
print, '[idl-ucrio] Compiling routines'

; set paths for AACGM data files
;
; NOTE: IDL-UCRio expects all AACGM_v2 files to be located within !packages_path by default.
;       If AACGM_v2 code / text files are not located in '*\.idl\idl\packages\idl_ucrio\libs\aacgm',
;       alter the below filepath to point to a different location by default.
igrf_coeffs = !package_path + path_sep() + 'idl_ucrio' + path_sep() + $
  'libs' + path_sep() + 'aacgm' + path_sep() + 'magmodel_1590-2025.txt'
aacgm_dat_prefix = !package_path + path_sep() + 'idl_ucrio' + path_sep() + $
  'libs' + path_sep() + 'aacgm' + path_sep() + 'coeffs' + path_sep() + 'aacgm_coeffs-14-'
; igrf_coeffs = 'C:\Users\darrenc\Documents\GitHub\idl-UCRio\libs\aacgm\magmodel_1590-2025.txt'
; aacgm_dat_prefix = 'C:\Users\darrenc\Documents\Github\idl-UCRio\libs\aacgm\coeffs\aacgm_coeffs-14-'

; check paths for AACGM
igrf_coeffs_exist = file_test(igrf_coeffs)
!null = file_search(aacgm_dat_prefix+'*', count=aacgm_dat_exists)
if ((igrf_coeffs_exist eq 0) or (aacgm_dat_exists eq 0)) then aacgm_found = 0
if ((igrf_coeffs_exist ne 0) and (aacgm_dat_exists ne 0)) then aacgm_found = 1

; initialize AACGM
setenv, 'AACGM_v2_DAT_PREFIX=' + aacgm_dat_prefix
setenv, 'IGRF_COEFFS=' + igrf_coeffs

.run genmag
.run igrflib_v2
.run aacgmlib_v2
.run aacgm_v2
.run time
.run astalg
.run mlt_v2

; top level
.run ucrio_version
.run ucrio_proxy

; helpers
;
; NOTE: these are here since they need to be compiled before some of 
; the following routines
.run ucrio_requests

; data
.run ucrio_list_datasets
.run ucrio_get_dataset
.run ucrio_list_observatories
.run ucrio_get_urls
.run ucrio_download
.run ucrio_readfile_norstar
.run ucrio_readfile_hsr
.run ucrio_read
.run ucrio_is_read_supported

; tools
.run ucrio_get_decomposed_color
.run ucrio_plot
.run ucrio_map_oplot

; check if there's a new version available
print, '[idl-ucrio] Checking for new version ...'
version_info = ucrio_check_version(/init_mode)
version_info = hash(version_info, /lowercase)
if (version_info['new_version_available'] eq 1) then print, '[idl-ucrio] ' + version_info['message'].replace('[ucrio_check_version] ', '')

; finish
print, '[idl-ucrio] Initialization complete'

; Check if the AACGM files necessary for environment variable to work were found.
; If they, weren't, print a message to notify the user
if aacgm_found eq 0 then print, '[idl-ucrio] Warning: could not initialize AACGM_v2 library. IDL-UCRio expects the AACGM coefficient and ' + $
  'magmodel_1590-2025.txt files to be saved at idl_ucrio' + path_sep() + 'libs' + path_sep() + 'aacgm' + path_sep() + '. If these files are saved ' + $
  'elsewhere, you can (A) alter the ucrio_startup.pro file lines 25-28 to the correct paths (RECOMMENDED) or (b) manually set the environment variables ' + $
  'for AACGM every time you run @ucrio_startup, using the commands: `IDL> setenv, "AACGM_v2_DAT_PREFIX=...magmodel_1590-2025.txt"` and ' + $
  '`IDL> setenv, "IGRF_COEFFS=...coeffs' + path_sep() + 'aacgm_coeffs-14-"`.'
