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
;       Plot riometer data as combined line plots, or a stack plot. Used for plotting
;       both single-frequency riometer data and hyper-spectral riometer (HSR) data,
;       either seperately or together.
;
; :Parameters:
;       rio_data: in, required, Struct or Float
;         the data to be plotted. A struct or a list of riometer data structs, i.e.
;         the return of calling `ucrio_read()` on files from a riometer dataset.
;
; :Keywords:
;       absorption: in, optional, Bool
;         plot absorption data, as opposed to raw data. Defaults to False.
;       stack_plot: in, optional, Bool
;         render plots into a stack-plot of subplots for each data struct. Defaults to False.
;       downsample_seconds: in, optional, Int
;         the window size for smoothing data before plotting. Default is 1, which is the same as the data
;         temporal resolutions, meaning no smoothing will occur.
;       hsr_bands: in, optional, Int
;         the band indices to be plotted, specifically applicable to HSR data. By default,
;         all bands will be plotted.
;       color: in, optional, Str or Int
;         string or RGB triple(s) specifying the color(s) to use for plotting
;       dimensions: in, optional, Array
;         two-element array giving dimensions of the plotting window in device coordinates
;       location: in, optional, Array
;         two-element array giving location of the plotting window in device coordinates
;       xtitle: in, optional, String
;         string giving the x-axis title
;       ytitle: in, optional, String
;         string giving the y-axis title
;       linestyle: in, optional, String or Int
;         string(s) or int(s) specifying the linestyle(s) to use for plotting
;       xformat: in, optional, String
;         string specifying the format for time axis labels. available formats are
;         'HH' (default), 'HH:MM', or 'HH:MM:SS'
;       thick: in, optional, Int
;         integer specifying the line thickness to use for plotting, defaults to 1
;       margin: in, optional, Float
;         float or 4-element vector giving the margin (whitespace) in normal coords
;         to add to the edge of the plot(s)
;
; :Returns:
;       reference to the created graphic
;
; :Examples:
;       d = ucrio_download('SWAN_HSR_K0_H5', '2024-03-03T00:00:00', '2024-03-03T23:59:59', site_uid = 'rabb')
;       data = ucrio_read(d.dataset, d.filenames)
;       p = ucrio_plot(data, title="Riometer Data", color="red", dimensions=[1000,400], hsr_bands=[0,5])
;+
function ucrio_plot, $
  rio_data, $
  absorption = absorption, $
  stack_plot = stack_plot, $
  downsample_seconds = downsample_seconds, $
  hsr_bands = hsr_bands, $
  color = color, $
  dimensions = dimensions, $
  location = location, $
  xtitle = xtitle, $
  ytitle = ytitle, $
  yrange = yrange, $
  linestyle = linestyle, $
  xformat = xformat, $
  thick = thick, $
  margin = margin
  ; Convert single rio_data to list for iteration
  if isa(rio_data, 'STRUCT') then rio_data_list = list(rio_data) else rio_data_list = rio_data

  if isa(xformat) then begin
    if total(strmatch(['HH', 'HH:MM', 'HH:MM:SS'], xformat)) ne 1 then begin
      print, '[ucrio_plot] Error: invalid value for keyword ''xformat''. Accepted values are ''HH'', ''HH:MM'', or ''HH:MM:SS'''
      return, !null
    endif else begin
      if (xformat = 'HH') then xformatstr = '(C(CHI2.2))'
      if (xformat = 'HH:MM') then xformatstr = '(C(CHI2.2,":",CMI2.2))'
      if (xformat = 'HH:MM:SS') then xformatstr = '(C(CHI2.2,":",CMI2.2,":",CMS2.2))'
    endelse
  endif else xformatstr = '(C(CHI2.2))'

  if keyword_set(thick) then thickness = thick else thickness = 1
  if keyword_set(margin) then plot_margin = margin else plot_margin = [0.1, 0.2, 0.1, 0.1]

  ; init colors
  if keyword_set(color) then begin
    if isa(color, /scalar) then color_list = [color] else color_list = color
  endif else begin
    color_list = ['red', 'orange', 'green', 'blue', 'purple']
  endelse

  ; init linestyles
  if keyword_set(linestyle) then begin
    if isa(linestyle, /scalar) then linestyle_list = [linestyle] else linestyle_list = linestyle
  endif else begin
    linestyle_list = ['-']
  endelse

  ; First, iterate through each data struct and make sure that
  ; requested plotting parameters are valid for datasets
  total_plots = 0l
  input_datasets = []
  foreach data, rio_data_list do begin
    dset = data.dataset.name
    ; Check dataset
    if total(strmatch(['SWAN_HSR_K0_H5', 'NORSTAR_RIOMETER_K2_TXT'], dset)) ne 1 then begin
      print, '[ucrio_plot] Error: plotting function is not currently available for dataset ' + dset
      return, !null
    endif
    input_datasets = [input_datasets, dset]

    ; Check number of plots required
    if dset eq 'SWAN_HSR_K0_H5' then begin
      if keyword_set(hsr_bands) then begin
        if isa(hsr_bands, /array) then total_plots += n_elements(hsr_bands) else total_plots += 1
      endif else begin
        total_plots += n_elements(data.data[0].band_central_frequency)
      endelse
    endif else begin
      ; NORSTAR will always constitute one plot
      total_plots += 1
    endelse
  endforeach

  ; Create full list of colors to cycle through
  if n_elements(color_list) ne total_plots then begin
    master_color_list = []
    while n_elements(master_color_list) lt total_plots do begin
      foreach clr, color_list do master_color_list = [master_color_list, clr]
    endwhile
  endif else master_color_list = color_list

  ; Create full list of linestyles to cycle through
  if n_elements(linestyle_list) ne total_plots then begin
    master_linestyle_list = []
    while n_elements(master_linestyle_list) lt total_plots do begin
      foreach ls, linestyle_list do master_linestyle_list = [master_linestyle_list, ls]
    endwhile
  endif else master_linestyle_list = linestyle_list

  ; Don't allow HSR and NORSTAR data on the same axis
  if n_elements(input_datasets[uniq(input_datasets, sort(input_datasets))]) ne 1 and (keyword_set(stack_plot) eq 0) then begin
    print, '[ucrio_plot] Error: Cannot plot multiple datasets on the same set of axes.'
    return, !null
  endif

  ; Check window params and set defaults
  if not keyword_set(dimensions) then begin
    if keyword_set(stack_plot) then dimensions = [600, 1000] else dimensions = [800, 400]
  endif
  if not keyword_set(location) then location = [0, 0]

  ; Create plotting window
  !null = window(dimensions = dimensions, location = location)

  ; Iterate through each data object in list
  current_axis_idx = 0l
  master_legend_reference = []
  foreach data, rio_data_list do begin
    ; Get dataset and site name
    dataset = data.dataset.name
    site = (data.metadata[0])['site_unique_id']

    ; Initialize array for timestamps and hash (to seperate bands) for data
    time_stamp = []
    data_dict = hash()

    ; Initialize array to automatiacally determine axis name
    y_axis_names = []

    ; Iterate through each Riometer / HSR data object (i.e. iterate across days if there were
    ; multiple read in as they will be split in a list)
    foreach d, data.data, d_idx do begin
      ; Append to timestamp
      time_stamp = [time_stamp, data.timestamp[d_idx]]

      ; Get the bands of interest and name them for tracking
      band_names = []
      if (dataset eq 'SWAN_HSR_K0_H5') then begin
        ; Get band indices
        if (not keyword_set(hsr_bands)) then begin
          bands = indgen(n_elements(d.band_central_frequency))
        endif else begin
          bands = hsr_bands
        endelse

        ; Set band names
        foreach band_idx, bands do begin
          band_name = strupcase(site) + ' HSR Band-' + string(band_idx, '(I2.2)') + ' ' + $
            strcompress(string(round(d.band_central_frequency[band_idx] * 10.0) / 10.0, format = '(F4.1)'), /remove_all) + ' MHz'
          band_names = [band_names, band_name]
        endforeach

        ; Set y-axis name
        foreach i, bands do begin
          if (keyword_set(absorption)) then y_axis_names = [y_axis_names, 'Absorption (dB)'] else y_axis_names = [y_axis_names, 'Raw Power (dB)']
        endforeach
      endif else begin
        ; Default band for non-HSR data is 30 MHz
        bands = [0]
        band_name = strupcase(site) + ' Riometer 30.0 MHz'
        band_names = [band_names, band_name]

        ; Set y-axis name
        if (keyword_set(absorption)) then y_axis_names = [y_axis_names, 'Absorption (dB)'] else y_axis_names = [y_axis_names, 'Raw Signal (V)']
      endelse

      ; Pull out the data array of interest from the Riometer or HSR data object
      if (dataset eq 'NORSTAR_RIOMETER_K0_TXT') or (dataset eq 'NORSTAR_RIOMETER_K2_TXT') then begin
        if keyword_set(absorption) then begin
          ; Check if there is absorption data if requested
          if (isa(d.absorption, /scalar) eq 1) then begin
            if (not finite(d.absorption)) then begin
              print, '[ucrio_plot] Warning: omitting plotting (no absorption data) for ' + dataset
              continue
            endif
          endif else begin
            for k = 0, n_elements(bands) - 1 do begin
              data_arr = d.absorption
              if (n_elements(data_dict) ne 0) then begin
                if strmatch((data_dict.keys()).toArray(), band_names[k]) then begin
                  data_dict[band_names[k]] = [data_dict[band_names[k]], data_arr]
                endif
              endif else begin
                data_dict[band_names[k]] = data_arr
              endelse
            endfor
          endelse
        endif else begin ; absorption *not* requested
          for k = 0, n_elements(bands) - 1 do begin
            data_arr = d.raw_signal
            if (n_elements(data_dict) ne 0) then begin
              if strmatch((data_dict.keys()).toArray(), band_names[k]) then begin
                data_dict[band_names[k]] = [data_dict[band_names[k]], data_arr]
              endif
            endif else begin
              data_dict[band_names[k]] = data_arr
            endelse
          endfor
        endelse
      endif else if (dataset eq 'SWAN_HSR_K0_H5') then begin
        if keyword_set(absorption) then begin
          ; Check if there is absorption data if requested
          if (isa(d.absorption, /scalar) eq 1) then begin
            if (not finite(d.absorption)) then begin
              print, '[ucrio_plot] Warning: omitting plotting (no absorption data) for ' + dataset
              continue
            endif
          endif else begin
            for k = 0, n_elements(bands) - 1 do begin
              band_idx = bands[k]
              data_arr = d.absorption[*, band_idx]
              if (n_elements(data_dict) ne 0) then begin
                if total(strmatch((data_dict.keys()).toArray(), band_names[k])) ne 0 then begin
                  data_dict[band_names[k]] = [data_dict[band_names[k]], data_arr]
                endif
              endif else begin
                data_dict[band_names[k]] = data_arr
              endelse
            endfor
          endelse
        endif else begin ; absorption *not* requested
          for k = 0, n_elements(bands) - 1 do begin
            band_idx = bands[k]
            data_arr = d.raw_power[*, band_idx]
            if (n_elements(data_dict.keys()) ne 0) then begin
              if total(strmatch((data_dict.keys()).toArray(), band_names[k])) ne 0 then begin
                data_dict[band_names[k]] = [data_dict[band_names[k]], data_arr]
              endif else begin
                data_dict[band_names[k]] = data_arr
              endelse
            endif else begin
              data_dict[band_names[k]] = data_arr
            endelse
          endfor
        endelse
      endif
    endforeach

    ; Iterate through each data array we are plotting
    for j = 0, n_elements(data_dict.keys()) - 1 do begin
      ; init
      signal_name = (data_dict.keys())[j]
      signal_data = (data_dict.values())[j]
      auto_ytitle = y_axis_names[j]

      ; Set layout for current plotting axis
      if keyword_set(stack_plot) then begin
        layout = [1, total_plots, current_axis_idx + 1]
      endif else begin
        layout = [1, 1, 1]
      endelse

      if keyword_set(downsample_seconds) then begin
        if (not isa(downsample_seconds, /scalar, /int)) or (downsample_seconds lt 1) then begin
          print, '[ucrio_plot] Error: keyword ''downsample_seconds'' must be a scalar integer > 1'
          return, !null
        endif

        ; downsample with simple moving average
        signal_data = smooth(signal_data, downsample_seconds)
      endif

      ; Conver timestamps into julian dates
      juldt = julday(fix(strmid(time_stamp, 5, 2)), fix(strmid(time_stamp, 8, 2)), fix(strmid(time_stamp, 0, 4)), $
        fix(strmid(time_stamp, 11, 2)), fix(strmid(time_stamp, 14, 2)), fix(strmid(time_stamp, 17, 2)))

      if keyword_set(stack_plot) then overplot = 0 else overplot = 1
      if current_axis_idx eq 0 then overplot = 0

      clr = master_color_list[current_axis_idx]
      lnstyl = master_linestyle_list[current_axis_idx]

      ; Plot the data
      p = plot(juldt, signal_data, color = clr, linestyle = lnstyl, overplot = overplot, /current, layout = layout, $
        xtickunits = 'Time', xtickformat = xformatstr, thick = thickness, name = signal_name, margin = plot_margin)

      ; Increment axis for stack plotting
      current_axis_idx += 1

      ; Create individual per-plot legends for stack plots, otherwise save
      ; plot reference to create an overall legend later
      if keyword_set(stack_plot) then begin
        l = legend(target = [p], position = p.position[2 : 3], color = 'white', transparency = 100)
      endif else begin
        master_legend_reference = [master_legend_reference, p]
      endelse

      ; Add y-title
      if keyword_set(ytitle) then p.ytitle = ytitle else p.ytitle = auto_ytitle

      ; Add x-title
      if keyword_set(xtitle) then p.xtitle = xtitle else begin
        if xformatstr eq '(C(CHI2.2))' then begin
          p.xtitle = 'Hour (UTC)'
        endif else if xformatstr eq '(C(CHI2.2,":",CMI2.2))' then begin
          p.xtitle = 'Time (UTC)'
        endif else if xformatstr eq '(C(CHI2.2,":",CMI2.2,":",CMS2.2))' then begin
          p.xtitle = 'Time (UTC)'
        endif
      endelse

      ; Set y-limit
      if keyword_set(yrange) then p.yrange = yrange
    endfor
  endforeach

  if not keyword_set(stack_plot) then l = legend(target = master_legend_reference, position = master_legend_reference[0].position[2 : 3], color = 'white', transparency = 100)
end
