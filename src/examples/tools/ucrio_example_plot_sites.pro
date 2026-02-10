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

pro ucrio_example_plot_sites
  ; -------------------
  ; Plot Riometer Sites
  ; -------------------
  ;
  ; By leveraging the API access functions available through IDL-UCrio, it is
  ; straightforward to make maps of an instrument's location, at specific sites,
  ; or across all sites. Below are several examples of doing so.
  ;

  ; The first step will always be to create your map projection in
  ; a plotting window, so we can overplot sites.
  map_bounds = [40, 220, 80, 290]

  water_color = ucrio_get_decomposed_color([64, 89, 120])
  border_color = ucrio_get_decomposed_color([0, 0, 0])
  border_thick = 2
  window_bg_color = ucrio_get_decomposed_color([0, 0, 0])
  window, 0, xsize = 500, ysize = 300, xpos = 0, ypos = 0
  map_win_loc = [0., 0., 1., 1.]
  device, decomposed = 1
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, 56, 255, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, mlinethick = border_thick

  ; Let's set the font so things look a bit nicer
  !p.font = 1
  device, set_font = 'Helvetica Bold', /tt_font, set_character_size = [15, 15]
  ; Define a usersymbol that is just a filled circle
  usersym, cos(findgen(16) * (!pi * 2 / 16.)), sin(findgen(16) * (!pi * 2 / 16.)), /fill

  ; --------------------------------------
  ; Plotting FoV for an instrument by site
  ;
  ; Using `ucrio_list_observatories()' let's obtain the lat/lon coordinates
  ; of the SWAN HSR site located at Meanook, AB (MEAN)
  ;
  result = ucrio_list_observatories('swan_hsr')
  foreach record, result do begin
    if record.uid eq 'mean' then begin
      lat = record.geodetic_latitude
      lon = record.geodetic_longitude
    endif
  endforeach

  ; Plot this site on the map
  red = ucrio_get_decomposed_color([255, 0, 0])
  plots, lon, lat, /data, psym = 8, color = red

  ; Add a label
  xyouts, lon + 0.5, lat + 0.5, 'MEAN', /data, color = red

  ; -------------------------------------
  ; Plotting an entire array of riometers
  ;
  ; Maybe you'd like to see the location of all NORSTAR riometers. This
  ; can be achieved easily by plotting inside a loop
  ;

  ; First, create a new map
  window, 1, xsize = 800, ysize = 600, xpos = 810, ypos = 0
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, 56, 255, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, mlinethick = border_thick

  ; Define some colors for plotting in decomposed mode
  title_color = ucrio_get_decomposed_color([70, 15, 15])
  site_color = ucrio_get_decomposed_color([20, 150, 100])

  ; Add a title
  xyouts, 0.5, 0.025, 'NORSTAR Riometer Sites', color = title_color, /normal, alignment = 0.5, charsize = 1.5

  ; List the observatores that are part of the NORSTAR riometer array
  result = ucrio_list_observatories('norstar_riometer')
  foreach record, result do begin
    ; Grab site_uid, lat, lon
    site_uid = strupcase(record.uid)
    lat = record.geodetic_latitude
    lon = record.geodetic_longitude

    ; Plot site location and name
    plots, lon, lat, /data, psym = 8, color = site_color
    xyouts, lon + 0.5, lat + 0.5, site_uid, /data, color = site_color
  endforeach

  ; ----------------------------------------
  ; Adding geographic / geomagnetic contours
  ;
  ; IDL-UCRio also includes a function that can come in handy when plotting
  ; maps, called `ucrio_map_oplot()`. This function can be used to do all
  ; of the following:
  ;
  ; - Add lines of constant lat/lon
  ; - Add lines of constant geomagnetic (AACGM) lat/lon
  ; - Add custom lines defined in geographic space
  ; - Add custom lines defined in geomagnetic space
  ; - Plot custom points defined in geographic space
  ; - Plot custom points defined in geomagnetic space
  ; - All above functionality in the same procedure call
  ;
  ; As an example, let's add a geographic grid, as well as two lines
  ; of constant geomagnetic (AACGM) latitude
  ;

  ; Plot some gridlines
  gridline_color = ucrio_get_decomposed_color([0, 0, 0])
  clats = [30, 40, 50, 60, 70, 80]
  clons = [200, 220, 240, 260, 280, 300, 320, 340]
  ucrio_map_oplot, constant_lats = clats, constant_lons = clons, color = gridline_color, linestyle = 2

  ; The `ucrio_map_oplot` routine also includes a /mag option, to overplot contours
  ; that are defined in geomagnetic (AACGM) coordinates
  magnetic_gridline_color = ucrio_get_decomposed_color([255, 179, 0])
  clats = [63, 77]
  ucrio_map_oplot, constant_lats = clats, color = magnetic_gridline_color, linestyle = 0, thick = 6, /mag

  ; Note: the `ucrio_map_oplot` function will always plot on top. So
  ; it is usually best to call it before plotting the site locations.
  ; Let's replot them quickly
  foreach record, result do begin
    ; Grab site_uid, lat, lon
    site_uid = strupcase(record.uid)
    lat = record.geodetic_latitude
    lon = record.geodetic_longitude

    ; Plot site location and name
    plots, lon, lat, /data, psym = 8, color = site_color
    xyouts, lon + 0.5, lat + 0.5, site_uid, /data, color = site_color
  endforeach

  ; -------------------------------------------------
  ; Plotting sites from multiple riometer instruments
  ;
  ; Maybe you'd like to see the location of all NORSTAR riometers, as
  ; well as all SWAN HSR instruments. Thiscan be achieved using the
  ; same methodology employed above
  ;

  ; Again, create a new map
  window, 2, xsize = 800, ysize = 600, xpos = 0, ypos = 330
  polyfill, [0., 0., 1., 1.], [0., 1., 1., 0.], color = window_bg_color, /normal
  polyfill, [map_win_loc[0], map_win_loc[2], map_win_loc[2], map_win_loc[0]], [map_win_loc[1], map_win_loc[1], map_win_loc[3], map_win_loc[3]], color = water_color, /normal
  map_set, 56, 255, 0, sat_p = [20, 0, 0], /satellite, limit = map_bounds, position = map_win_loc, /noerase, /noborder ; <---- (Change Projection)
  map_continents, /fill, /countries, color = land_color
  map_continents, color = border_color, mlinethick = border_thick

  ; Define some colors for plotting in decomposed mode
  title_color = ucrio_get_decomposed_color([120, 15, 15])
  norstar_color = ucrio_get_decomposed_color([0, 200, 0])
  swan_color = ucrio_get_decomposed_color([0, 0, 220])
  gridline_color = ucrio_get_decomposed_color([0, 0, 0])
  magnetic_gridline_color = ucrio_get_decomposed_color([255, 179, 0])

  ; Plot some gridlines
  clats = [30, 40, 50, 60, 70, 80]
  clons = [200, 220, 240, 260, 280, 300, 320, 340]
  ucrio_map_oplot, constant_lats = clats, constant_lons = clons, color = gridline_color, linestyle = 2

  ; Plot some lines of constant magnetic latitude
  clats = [63, 77]
  ucrio_map_oplot, constant_lats = clats, color = magnetic_gridline_color, linestyle = 0, thick = 6, /mag

  ; Add a title
  xyouts, 0.5, 0.025, 'NORSTAR Riometer (Green) amd SWAN HSR (Blue)', color = title_color, /normal, alignment = 0.5, charsize = 1.5

  ; List the observatores that are part of the NORSTAR riometer array
  result = ucrio_list_observatories('norstar_riometer')
  foreach record, result do begin
    ; Grab site_uid, lat, lon
    site_uid = strupcase(record.uid)
    lat = record.geodetic_latitude
    lon = record.geodetic_longitude

    ; Plot site location and name
    plots, lon, lat, /data, psym = 8, color = norstar_color
    xyouts, lon + 0.5, lat + 0.5, site_uid, /data, color = norstar_color
  endforeach

  ; Repeat the process for the SWAN HSR Array
  result = ucrio_list_observatories('swan_hsr')
  foreach record, result do begin
    ; Grab site_uid, lat, lon
    site_uid = strupcase(record.uid)
    lat = record.geodetic_latitude
    lon = record.geodetic_longitude

    ; Plot site location and name
    plots, lon, lat, /data, psym = 8, color = swan_color
    xyouts, lon + 0.5, lat + 0.5, site_uid, /data, color = swan_color
  endforeach

  !p.font = -1
end
