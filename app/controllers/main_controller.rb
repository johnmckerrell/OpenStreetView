class MainController < ApplicationController

  def index
    @javascripts = [ 'http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js', 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js', 'jquery/jquery.json-2.2.min', 'jquery/boxer.js', '/openlayers/OpenLayers', '/openlayers/OpenStreetMap', 'OSV', 'OSVMain', 'OSVPhoto' ]
    @unlocated = Photo.find_unlocated
    @pageid = 'homepage'
  end

  def licenses
    @licenses = License.find(:all)
  end
end
