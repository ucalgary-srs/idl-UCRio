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
;       Configure IDL-UCRio library to utilize a proxy connection when communicating
;       with the API and the data archive.
;
; :Arguments:
;       hostname: in, required, String
;         The hostname for the proxy connection. Usually this is 'localhost'.
;       port: in, required, Integer
;         The port number for the proxy connection.
;
; :Keywords:
;       username: in, optional, String
;         The username for the proxy connection, if required.
;       password: in, optional, String
;         The password for the proxy connection, if required.
;
; :Examples:
;       ucrio_set_proxy,'localhost',9000
;       ucrio_set_proxy,'localhost',8888,username=someone,password=something
;+
pro ucrio_set_proxy, hostname, port, username = username, password = password
  ; set the hostname and port environment variables
  setenv, 'UCRIO_PROXY_HOSTNAME=' + hostname
  setenv, 'UCRIO_PROXY_PORT=' + string(port, format = '(I0)')

  ; set the username and password
  if (keyword_set(username) eq 0) then username = ''
  if (keyword_set(password) eq 0) then password = ''
  setenv, 'UCRIO_PROXY_USERNAME=' + username
  setenv, 'UCRIO_PROXY_PASSWORD=' + password
end

;+
; :Description:
;       Get the proxy connection details that the IDL-UCRio library will use when
;       communicating with the API and the data archive.
;
; :Returns:
;       Struct
;
; :Examples:
;       ucrio_get_proxy
;+
function ucrio_get_proxy
  ; get the values
  value_hostname = getenv('UCRIO_PROXY_HOSTNAME')
  value_port = getenv('UCRIO_PROXY_PORT')
  value_username = getenv('UCRIO_PROXY_USERNAME')
  value_password = getenv('UCRIO_PROXY_PASSWORD')

  ; set the return struct
  values = {hostname: value_hostname, port: value_port, username: value_username, password: value_password}

  ; return
  return, values
end

;+
; :Description:
;       Clear the proxy connection details that the IDL-UCRio library will use when
;       communicating with the API and the data archive.
;
; :Examples:
;       ucrio_clear_proxy
;+
pro ucrio_clear_proxy
  ; clear the hostname and port environment variables
  setenv, 'UCRIO_PROXY_HOSTNAME='
  setenv, 'UCRIO_PROXY_PORT='
  setenv, 'UCRIO_PROXY_USERNAME='
  setenv, 'UCRIO_PROXY_PASSWORD='
end