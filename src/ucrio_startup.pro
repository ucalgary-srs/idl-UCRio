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

; aacgm
setenv, 'AACGM_v2_DAT_PREFIX=' + !package_path + path_sep() + $
  'libs' + path_sep() + 'aacgm' + path_sep() + 'coeffs' + path_sep() + 'aacgm_coeffs-14-'
setenv, 'IGRF_COEFFS=' + !package_path + path_sep() + $
  'libs' + path_sep() + 'aacgm' + path_sep() + 'magmodel_1590-2025.txt'
.run genmag
.run igrflib_v2
.run aacgmlib_v2
.run aacgm_v2
.run time
.run astalg
.run mlt_v2

; top level
.run ucrio_version

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

; check if there's a new version available
print, '[idl-ucrio] Checking for new version ...'
version_info = ucrio_check_version(/init_mode)
version_info = hash(version_info, /lowercase)
if (version_info['new_version_available'] eq 1) then print, '[idl-ucrio] ' + version_info['message'].replace('[ucrio_check_version] ', '')

; finish
print, '[idl-ucrio] Initialization complete'
