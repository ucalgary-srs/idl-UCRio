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

pro ucrio_example_plot_data
  ; ------------------
  ; Plot Riometer Data
  ; ------------------
  ;
  ; IDL-UCRio includes a handy plotting function that can be used to easily plot
  ; riometer data, with control over several options.
  ;
  ; The function allows you to create plots of multiple sets of riometer data,
  ; either on one plot, or in a 'stack plot' manner. This crib sheet walks through
  ; the creation of several riometer data plots.
  ;
  ; Note: If you require more control over plotting than is offered by the `ucrio_plot()`
  ;       function, it is straightforward to just use manual IDL plotting routines on
  ;       the data after obtaining it via `ucrio_download()` and `ucrio_read()`.
  ;
  
  ; ---------------------
  ; NORSTAR Riometer Data
  ; 
  ; First, let's start by downloading some k0 data from the NORSTAR riometers
  data_list = list()
  sites = ['chur', 'daws', 'rabb']
  foreach site, sites do begin
    d = ucrio_download('NORSTAR_RIOMETER_K2_TXT', '2023-11-05T00:00:00', '2023-11-05T23:59:59', site_uid = site)
    data = ucrio_read(d.dataset, d.filenames, start_dt = '2023-11-05T00:00:00', end_dt = '2023-11-05T23:59:59' )
    data_list.add, data
  endforeach
  
  ; Let's just make a single plot of the data from all three sites, for one day
  p = ucrio_plot(data_list, yrange=[0,10])
  
  ; The NORSTAR k2 files contain both raw signal, as well as absorption data... using
  ; a keyword in `ucrio_plot()`, let's plot absorption instead:
  p = ucrio_plot(data_list, yrange=[0,5], /absorption, location=[0,200])
  
  ; Let's re-read the riometer data, this time using the `start_dt` and `end_dt` keywords
  ; within the `ucrio_read()` function, so we limit our plotting range
  data_list = list()
  foreach site, sites do begin
    d = ucrio_download('NORSTAR_RIOMETER_K2_TXT', '2023-11-05T00:00:00', '2023-11-05T23:59:59', site_uid = site)
    data = ucrio_read(d.dataset, d.filenames, start_dt = '2023-11-05T11:00:00', end_dt = '2023-11-05T11:59:59' )
    data_list.add, data
  endforeach

  ; Call the plotting function again, this time formatting timestamps differently, and downsampling
  p = ucrio_plot(data_list, yrange=[0,5], /absorption, xformat='HH:MM', downsample_seconds=5, location=[0,400])
  
  ; -------------
  ; SWAN HSR Data
  ;
  ; Now, let's have a look at some SWAN hyper-spectral riometer (HSR) data.
  ; 
  ; Again, download and read in a few hours of data from two sites
  data_list = list()
  sites = ["medo", "russ"]
  foreach site, sites do begin
    d = ucrio_download('SWAN_HSR_K0_H5', '2023-11-05T04:00:00', '2023-11-05T13:59:59', site_uid = site)
    data = ucrio_read(d.dataset, d.filenames, start_dt = '2023-11-05T04:00:00', end_dt = '2023-11-05T13:59:59' )
    data_list.add, data
  endforeach
  
  ; NORSTAR riometer data is taken at a single frequency (30 MHz). However, HSR data is taken at many frequencies. The k0
  ; data that is provided are selected frequencies that are configured by the instrument operations team for the best
  ; results.
  ;
  ; We can look at the various bands available by looking closer at the HSR data structure we get from reading.
  ;
  help, data_list[0].data[0]
  print
  print, 'Available Frequencies:'
  print, data_list[0].data[0].band_central_frequency
  print
  print, 'Respective Passbands:'
  print, data_list[0].data[0].band_passband
  print
  
  ; You'll notice that the 0th index of the `band_central_frequency` and `band_passband` parameters is the 30 MHz band.
  ; This is done on purpose, so that the first band of HSR data is always the same as the traditional riometers.
  ; 
  ; Ok, now that we know about the fact that HSR data has multiple bands, let's plot a few of them.
  
  ; Plot band_00 and band_05
  bands = [0,5]
  p = ucrio_plot(data_list, yrange=[0,100], location=[0,600], hsr_bands=bands, color=['blue','red'], downsample_seconds=10)
  
  ; If you'd like to plot a larger number of bands, a stack-plot can be easier to read
  ;
  ; Let's make one, using the `stack_plot` keyword available for `ucrio_plot()`
  hsr_bands = [0,3,5,7]
  colors = ['red', 'orange','green','blue']
  p = ucrio_plot(data_list, yrange=[0,80], location=[600,0], hsr_bands=hsr_bands, color=colors, thick=3, /stack_plot)

end
