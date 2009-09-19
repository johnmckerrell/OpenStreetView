function OSVPhoto(data, moderator) {
    this.data = data;
    this.moderator = moderator;
    this._selected = true;
    this.change_data = {};
    this.saving = false;
}

OSVPhoto.prototype.changed = function() {
    for( var k in this.change_data ) {
        if( this.change_data[k] != undefined )
            return true;
    }
    return false;
}

OSVPhoto.prototype.save = function() {
    if( this.saving )
        return;
    if( ! this.changed() )
        return;
    this.saving = true;
    this.saveLoop();
};

OSVPhoto.prototype.saveLoop = function(saved,args) {
    console.log(arguments);
    var data, status;
    if(saved) {
        data = args[0];
        status = args[1];
        if( status == 'success' && data && ! data.error ) {
            this.change_data[saved] = null;
        } else {
            OSV.reportError('There was an error saving your changes');
            return;
        }
    }
    var me = this;
    if( this.change_data.tags ) {
        var tags = [];
        for( var i = 0, l = this.change_data.tags.length; i < l; ++i ) {
            var t = this.change_data.tags[i];
            tags.push( {
                'id': t.id,
                'key': t.key,
                'value' : t.value,
                'area' : t.area,
                'deleting_user_id' : t.deleting_user_id
            });
        }
        var postData = $.toJSON(tags);
        var cb = function(){me.saveLoop('tags',arguments)};
        var url = '/api/photo/'+this.data.id+'/mask/?authenticity_token='+encodeURIComponent(OSV.getAuthenticityToken());
        $.ajax({
            'data': postData,
            'dataType': 'json',
            'error': cb,
            'success': cb,
            'type': 'POST',
            'url': url
            });
    } else  if( this.change_data.status ) {
        var data = { 'status' : this.change_data.status };
        var postData = $.toJSON(data);
        var cb = function(){me.saveLoop('status',arguments)};
        var url = '/api/photo/'+this.data.id+'/moderate/?authenticity_token='+encodeURIComponent(OSV.getAuthenticityToken());
        $.ajax({
            'data': postData,
            'dataType': 'json',
            'error': cb,
            'success': cb,
            'type': 'POST',
            'url': url
            });
        /*
        $.post( ,
            postData,
            function(json){me.saveCallback(json)},
            'json' );
            */
    } else if( saved ) {
        this.saving = false;
        this.change_data = {};
        this.data = data;
        if( this.safeness() == 'safe' ) {
            this.moderator.remove(this);
        } else {
            this.safeness(this.safeness());
            this.updateURL();
        }
    }
}

/*
    // No longer used, all done in saveLoop above
OSVPhoto.prototype.saveCallback = function(data,status) {
    console.log('saveCallback',arguments);
    if( status == 'success' && data && ! data.error ) {
        this.change_data = {};
        this.data = data;
        this.safeness(this.safeness());
        if( this.safeness() == 'safe' ) {
            this.moderator.remove(this);
        }
    } else {
        OSV.reportError('There was an error saving your changes');
    }
}
*/

OSVPhoto.prototype.html = function() {
    var html = $(document.createElement('li'));


    var a = document.createElement('a');
    html.append(a);
    a.href = 'javascript:void(0)';
    var me = this;
    a.onclick = function() {
        me.selected(!me.selected());
    }

    var img = document.createElement('img');
    a.appendChild(img);
    img.src = this.url('small');
    
    this.html = function() {
        return html;
    }
    this.destroy = function() {
        html.remove();
    }
    this.selected(this.selected());
    this.safeness(this.safeness());
    return this.html();
}

OSVPhoto.prototype.selected = function(sel) {
    if( sel != undefined ) {
        this._selected = sel ? true : false;
        if( this._selected ) {
            this.html().addClass('selected');
        } else {
            this.html().removeClass('selected');
        }
    }
    return this._selected;
}

OSVPhoto.prototype.updateURL = function() {
    var img = this.html().find('img');
    img.attr('src',this.url('small')+'?'+Math.random());
}

OSVPhoto.prototype.safeness = function(val) {
    if( val == 'safe' || val == 'unsafe' || val == 'pending' ) {
        var old = this.safeness();
        if( old && old != val ) {
            this.change_data.status = val;
        }
        if( old ) {
            this.html().removeClass(' status-'+old);
            this.html().addClass(' status-'+this.safeness());
        }
    }
    if( this.change_data.status )
        return this.change_data.status;
    if( this.data.moderator )
        return this.data.moderator.status;
    return;
}

OSVPhoto.prototype.addTag = function(t) {
    if( ! this.change_data.tags )
        this.change_data.tags = [];
    if( t.deleting_user_id ) {
        // Bit of a cheat, we add this tag by removing
        // it from the change_data, we do that by
        // pretending it's new and calling removeTag
        t.is_new = true;
        this.removeTag(t);
        t.is_new = false;
    } else {
        t.is_new = true;
        this.change_data.tags.push(t);
    }
    console.log(this);
}

OSVPhoto.prototype.removeTag = function(t) {
    if( t.is_new ) {
        var ct = [];
        for( var i = 0, l = this.change_data.tags.length; i < l; ++i ) {
            var cdt = this.change_data.tags[i];
            if( cdt != t )
                ct.push(cdt);
        }
        this.change_data.tags = ct;
    } else {
        if( ! this.change_data.tags )
            this.change_data.tags = [];
        for( var i = 0, l = this.data.tags.length; i < l; ++i ) {
            if( this.data.tags[i] == t ) {
                this.change_data.tags.push(t);
                t.deleting_user_id = true;
                break;
            }
        }
    }
    if( this.change_data.tags && this.change_data.tags.length == 0 ) {
        this.change_data.tags = null;
    }
    console.log(this);
}

OSVPhoto.prototype.destroy = function() {
}

OSVPhoto.prototype.url = function(type) {
    var url = '/';
    if( this.data.status != 'available' ) {
        url += 'private/processed/';
    } else {
        url += 'available/';
    }
    url += this.data.filename + '-' + type + '.jpg';
    return url;
}
