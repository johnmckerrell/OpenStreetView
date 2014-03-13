class MainController < ApplicationController

  def index
    # jquery/jquery-1.3.2.min.js = http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js
    # jquery/jquery.ui-1.7.2.min.js = http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js
    @javascripts = [ 'jquery/jquery-1.3.2.min.js', 'jquery/jquery.ui-1.7.2.min.js', 'jquery/jquery.json-2.2.min', 'jquery/boxer.js', 'http://www.openlayers.org/api/OpenLayers.js', '/openlayers/OpenStreetMap', 'OSV', 'OSVMain', 'OSVPhoto' ]
    @unlocated = Photo.find_unlocated
    @pageid = 'homepage'
  end

  def licenses
    @licenses = License.find(:all)
  end
end
