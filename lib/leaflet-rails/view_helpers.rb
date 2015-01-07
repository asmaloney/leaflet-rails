module Leaflet
  module ViewHelpers

    def map(options)
      defaults = {
        tile_layer: Leaflet.tile_layer,
        attribution: Leaflet.attribution,
        max_zoom: Leaflet.max_zoom,
        subdomains: Leaflet.subdomains,
        container_id: 'map'
      }

      options = defaults.merge( options )

      output = []
      output << "<div id='#{options[:container_id]}'></div>" unless options[:no_container]
      output << "<script>"
      output << "(function( L ) {"
      output << "var map = L.map('#{options[:container_id]}'), marker"

      if options[:center]
        output << "map.setView([#{options[:center][:latlng][0]}, #{options[:center][:latlng][1]}], #{options[:center][:zoom]})"
      end

      if options[:markers]
        options[:markers].each_with_index do |marker, index|
          if marker[:icon]
            if marker[:awesome_marker]
              icon_settings = prep_awesome_marker_settings(marker[:icon])
              output << "var #{icon_var_name(icon_settings[:name], index)} = L.AwesomeMarkers.icon({icon: '#{icon_settings[:name]}', prefix: '#{icon_settings[:prefix]}', markerColor: '#{icon_settings[:marker_color]}', iconColor:  '#{icon_settings[:icon_color]}', spin: '#{icon_settings[:spin].to_s}', extraClasses: '#{icon_settings[:extra_classes]}'})"
            else
              icon_settings = prep_icon_settings(marker[:icon])
              output << "var #{icon_var_name(icon_settings[:name], index)} = L.icon({iconUrl: '#{icon_settings[:icon_url]}', shadowUrl: '#{icon_settings[:shadow_url]}', iconSize: #{icon_settings[:icon_size]}, shadowSize: #{icon_settings[:shadow_size]}, iconAnchor: #{icon_settings[:icon_anchor]}, shadowAnchor: #{icon_settings[:shadow_anchor]}, popupAnchor: #{icon_settings[:popup_anchor]}})"
            end
            output << "marker = L.marker([#{marker[:latlng][0]}, #{marker[:latlng][1]}], {icon: #{icon_var_name(icon_settings[:name], index)}}).addTo(map)"
          else
            output << "marker = L.marker([#{marker[:latlng][0]}, #{marker[:latlng][1]}]).addTo(map)"
          end
          if marker[:popup]
            output << "marker.bindPopup('#{marker[:popup]}')"
          end
        end
      end

      if options[:fit_to_markers] && options[:markers] && (options[:markers].count > 1)
        locations = options[:markers].collect { |m| [m[:latlng][0].to_f, m[:latlng][1].to_f]  }

        output << "map.fitBounds( L.latLngBounds( #{locations} ), {"

        if options[:fit_to_markers].is_a? Hash
          padding = options[:fit_to_markers][:padding] 
          output << "padding: [#{padding}, #{padding}]," if padding

          max_zoom = options[:fit_to_markers][:max_zoom]
          output << "maxZoom: #{max_zoom}," if max_zoom
        end

        output << "} );"
      end

      if options[:circles]
        options[:circles].each do |circle|
          output << "L.circle(['#{circle[:latlng][0]}', '#{circle[:latlng][1]}'], #{circle[:radius]}, {
           color: '#{circle[:color]}',
           fillColor: '#{circle[:fillColor]}',
           fillOpacity: #{circle[:fillOpacity]}
        }).addTo(map);"
        end
      end

      if options[:polylines]
         options[:polylines].each do |polyline|
           _output = "L.polyline(#{polyline[:latlngs]}"
           _output << "," + polyline[:options].to_json if polyline[:options]
           _output << ").addTo(map);"
           output << _output.gsub(/\n/,'')
         end
      end

      if options[:fitbounds]
        output << "map.fitBounds(L.latLngBounds(#{options[:fitbounds]}));"
      end

      output << "L.tileLayer('#{options[:tile_layer]}', {
          attribution: '#{options[:attribution]}',
          maxZoom: #{options[:max_zoom]},"
        if options[:subdomains]
          output << "    subdomains: #{options[:subdomains]},"
        end
      output << "}).addTo(map)"

      output << "}) (L);"
      output << "</script>"
      output.join("\n").html_safe
    end

    private

    def icon_var_name(name, index)
      "#{name.gsub('-', '')}#{index}"
    end

    def prep_icon_settings(settings)
      defaults = {
        name: 'icon',
        shadow_url: '',
        icon_size: [],
        shadow_size: [],
        icon_anchor: [0, 0],
        shadow_anchor: [0, 0],
        popup_anchor: [0, 0]
      }

      defaults.merge( settings )
    end

    def prep_awesome_marker_settings(settings)
      defaults = {
        name: 'home',         # icon name, corresponds to 'icon' option in awesomeMarker
        prefix: 'glyphicon',  # 'fa' for font-awesome or 'glyphicon' for bootstrap 3
        marker_color: 'blue', # 'red', 'darkred', 'orange', 'green', 'darkgreen', 'blue', 'purple', 'darkpuple', 'cadetblue'
        icon_color: 'white',  # 'white'  'white', 'black' or css code (hex, rgba etc)
        spin: false,          # Make the icon spin 'true' or 'false'. Font-awesome required
        extra_classes: ''     # Allow additional custom configuration.
      }

      defaults.merge( settings )
    end

  end
end
