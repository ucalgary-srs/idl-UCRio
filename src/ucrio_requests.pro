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

function __generate_random_api_request_filename
  ; num chars
  num_chars = 8

  ; generate random numbers (uppercase A-Z, 0-9), which will later be converted into chars
  random_values = fix(randomu(!null, num_chars) * 36) ; Generate random numbers (0-35, total of possible numbers+chars)

  ; convert numbers to alphanumeric characters
  random_chars = ''
  for i = 0, num_chars - 1 do begin
    char_index = random_values[i]
    if (char_index lt 10) then begin
      ; digits 0-9
      random_chars += string(char_index, format = '(I1)')
    endif else begin
      ; letters A-Z (charIndex 10-35 maps to ASCII 65-90)
      random_chars += string(byte(65 + (char_index - 10)))
    endelse
  endfor

  ; concatenate final filename
  filename = getenv('IDL_TMPDIR') + 'idlucrio_api_request_' + random_chars + '.dat'

  ; return
  return, filename
end

function __ucrio_perform_api_request, request_type, print_header, req, post_str = post_str, expect_empty = expect_empty
  ; set proxy
  proxy_hostname = getenv('UCRIO_PROXY_HOSTNAME')
  proxy_port = getenv('UCRIO_PROXY_PORT')
  if (proxy_hostname ne '' and proxy_port ne '') then begin
    ; proxy hostname and port are configured, set them in the request object
    req.setProperty, proxy_host = proxy_hostname
    req.setProperty, proxy_port = fix(proxy_port)

    ; set username and password
    proxy_username = getenv('UCRIO_PROXY_USERNAME')
    proxy_password = getenv('UCRIO_PROXY_PASSWORD')
    if (proxy_username ne '') then req.setProperty, proxy_username = proxy_username
    if (proxy_password ne '') then req.setProperty, proxy_password = proxy_password
  endif

  ; set temp filename
  temp_filename = __generate_random_api_request_filename()

  ; check for error
  catch, error_status
  if (error_status ne 0) then begin
    catch, /cancel
    req.getProperty, response_code = response_code
    top_level_error_message = !error_state.msg
    obj_destroy, req

    ; read the response filename contents to extract the error message
    ;
    ; NOTE: we need to check if the file exists first, as the error
    ; could be upstream from an API mandated error, like a timeout
    ; or a bad gateway, etc.
    if (file_test(temp_filename) eq 0 or top_level_error_message ne '') then begin
      ; the error is upstream from the API
      error_message = top_level_error_message
    endif else begin
      openr, lun, temp_filename, /get_lun
      error_message = ''
      line = ''
      while not eof(lun) do begin
        readf, lun, line
        error_message = error_message + line
      endwhile
      free_lun, lun

      ; cleanup
      file_delete, temp_filename, /allow_nonexistent

      ; check if the usual Python API error message format exists, if so, then use it
      if (strpos(error_message, '"detail":') ne -1) then begin
        error_message = json_parse(error_message)
        error_message = error_message['detail']
      endif
    endelse

    ; evaluate error code
    print, '[' + print_header + '] Error performing request'
    print, '  API status code: ' + string(response_code, format = '(I0)')
    print, '  API error message: ' + error_message.toString()

    ; bail out
    return, {req: req, output: '', error_message: error_message, status_code: response_code}
  endif

  ; make request
  if (request_type eq 'post') then begin
    output = req.put(post_str, /buffer, /post, filename = temp_filename)
  endif else if (request_type eq 'get') then begin
    output = req.get(filename = temp_filename)
  endif

  ; extract status code
  req.getProperty, response_code = response_code

  ; read output
  output = ''
  if (not keyword_set(expect_empty)) then begin
    ; we don't expect an empty response, so we need to read it from
    ; the temp filename
    openr, lun, temp_filename, /get_lun
    output = ''
    line = ''
    while not eof(lun) do begin
      readf, lun, line
      output = output + line
    endwhile
    free_lun, lun
  endif

  ; cleanup
  file_delete, temp_filename, /allow_nonexistent

  ; return
  return, {req: req, output: output, error_message: '', status_code: response_code}
end
