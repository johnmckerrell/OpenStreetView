function OSVModerator(el) {
    this.area = $(el);
    this.ajax_activity = false;
    this.photos_list = this.area.find('.photo_list');
    this.photos_list.addClass('photo_list selectable');
    var me = this;
    this.area.find('.selectall').click(function() {me.setAll(true)});
    this.area.find('.selectnone').click(function() {me.setAll(false)});
    this.area.find('.markassafe').click(function(){me.markAllSafe('safe')});
    this.area.find('.markasunsafe').click(function(){me.markAllSafe('unsafe')});
    this.area.find('.savechanges').click(function(){me.save()});
    this.message = this.area.find('.nophotosmessge');
    this.message.find('a').click(function(){me.requestMoreImages()});
    var ta = this.area.find('.tagging_area');
    if( ta.get(0) ) {
        this.ta = new OSVTaggingArea(ta,true);
        this.area.find('.masksections').click(function(){me.maskSections()});
        this.maskCallbackWrapper = function() { me.maskCallback.apply(me,arguments); }
    }
    
    OSV.addChangeable(this);
    this.photos = [];
}

OSVModerator.prototype.maskSections = function() {
    var photos = [];
    for( var i = 0, l = this.photos.length; i < l; ++i ) {
        if( this.photos[i].selected() )
            photos.push(this.photos[i]);
    }
    this.ta.show(photos,this.maskCallbackWrapper);
}

OSVModerator.prototype.maskCallback = function( success ) {
}

OSVModerator.prototype.save = function() {
    var made_safe = false;
    for( var i = 0, l = this.photos.length; i < l; ++i ) {
        if( this.photos[i].changed() && this.photos[i].safeness() == 'safe' ) {
            made_safe = true;
            break
        }
    }
    if( made_safe && ! confirm( "Are you sure you want to mark these images as safe? You will not be able to undo this action." ) ) {
        return;
    }
    for( var i = 0, l = this.photos.length; i < l; ++i ) {
        this.photos[i].save();
    }
}

OSVModerator.prototype.changed = function() {
    for( var i = 0, l = this.photos.length; i < l; ++i ) {
        if( this.photos[i].changed() )
            return true;
    }
    return false;
}

OSVModerator.prototype.requestMoreImages = function() {
    if( this.ajax_activity )
        return;
    var me = this;
    this.ajax_activity = true;
    $.post( '/api/photos/request_more', null, function( json ) { me.requestMoreImagesCallback(json) }, 'json' );
}

OSVModerator.prototype.requestMoreImagesCallback = function(json) {
    this.ajax_activity = false;
    if( json && json instanceof Array ) {
        this.addImages(json);
    }
}

OSVModerator.prototype.requestImages = function() {
    var me = this;
    if( this.request_timeout )
        clearTimeout( this.request_timeout );
    request_timeout = setTimeout( function() {
        me.requestImagesTimeout();
        }, 100 );
}

OSVModerator.prototype.requestImagesTimeout = function() {
    if( this.ajax_activity )
        return;
    var me = this;
    this.ajax_activity = true;
    $.get( '/api/photos/?status=moderation', null, function( json ) { me.requestImagesCallback(json) }, 'json' );
}

OSVModerator.prototype.requestImagesCallback = function(json) {
    this.ajax_activity = false;
    if( json && json instanceof Array ) {
        while( this.photos.length ) {
            this.photos.shift().destroy();
        }
        this.addImages(json);
    }
}

OSVModerator.prototype.addImages = function( json ) {
    for( var i = 0, l = json.length; i < l; ++i ) {
        var p = new OSVPhoto(json[i],this);
        this.photos_list.append(p.html());
        this.photos.push(p);
    }
    if( this.photos.length == 0 ) {
        this.message.show();
    } else {
        this.message.hide();
    }
}

OSVModerator.prototype.remove = function(p) {
    var np = [];
    for( var i = 0, l = this.photos.length; i < l; ++i ) {
        if( this.photos[i] != p ) {
            np.push(this.photos[i]);
        }
    }
    this.photos = np;
    p.destroy();
    this.addImages([]);
}

OSVModerator.prototype.setAll = function(val) {
    if( this.ajax_activity )
        return;
    for( var i = 0, l = this.photos.length; i < l; ++i ) {
        this.photos[i].selected(val);
    }
}

OSVModerator.prototype.markAllSafe = function(safeness) {
    if( this.ajax_activity )
        return;
    for( var i = 0, l = this.photos.length; i < l; ++i ) {
        if( this.photos[i].selected() ) {
            this.photos[i].safeness(safeness);
        }
    }
}

