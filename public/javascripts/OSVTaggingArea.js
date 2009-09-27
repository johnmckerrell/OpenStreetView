function OSVTaggingArea(el, mask_tags) {
    this.html = $(el);
    this.photo_html = this.html.find('.photo');
    this.photo_html.bind('load',function() {
        this.style.visibility = 'visible';
    });
    this.tags_tbody = this.html.find('tbody');
    this.mask_tags = mask_tags;
    this.photos = null;
    this.current_photo = null;
    this.callback = null;
    this.area_box = null;

    if( mask_tags ) {
        this.html.find('.tag_key input').attr({'disabled':'disabled'})
    }

    var me = this;
    this.html.find('.window-actions .close').click(function(){me.hide()});
    this.html.find('.window-actions .next').click(function(){me.changePhoto(1)});
    this.html.find('.window-actions .previous').click(function(){me.changePhoto(-1)});
    this.html.find('.tag_area a').click(function() {
        me.html.find('.tag_area input').attr('value','');
    });
    this.html.find('form').bind('submit',function(){me.saveTag();return false;});
    this.photo_html.boxer( {
        appendTo: this.html.find('.photo_holder'),
        stop: function(event,ui){me.drawBoxFinish(event,ui);}} );
}

OSVTaggingArea.prototype.saveTag = function() {
    var tag = {};
    var area = this.html.find('form .tag_area input').attr('value');
    var key = this.html.find('form .tag_key input').attr('value');
    var value = this.html.find('form .tag_value input').attr('value');
    if( key && key != '' && value && value != '' ) {
        tag.mask_tag = this.mask_tags;
        tag.key = key;
        if( value && value != '' )
            tag.value = value;
        if( area && area != '' )
            tag.area = area;
        tag.area_box = this.area_box;
        this.photos[this.current_photo].addTag(tag);
        this.area_box = null;
        this.clearTagForm();
        this.tags_tbody.append(
            this.createTagHTML(tag,true,
                this.tags_tbody.get(0).childNodes.length ) );
    } else {
        this.changePhoto(1);
    }
}

OSVTaggingArea.prototype.addTagBox = function(area,mask) {
    var bits = area.split(/[ x,]/);
    if( bits.length != 4 )
        return;
    var box = $(document.createElement('div'));
    box.addClass( 'tag_area' );
    if( mask ) {
        box.addClass(' mask');
    }
    this.html.find('.photo_holder').append(box);
    box.css({
        "left":   1*bits[0],
        "top":    1*bits[1],
        "width":  1*bits[2],
        "height": 1*bits[3]
    });
    return $(box);
}

OSVTaggingArea.prototype.drawBoxFinish = function(event,ui) {
    if( this.area_box )
        this.area_box.remove();
    var holder = this.html.find('.photo_holder');
    holder.append(ui.box);
    
    var left = parseInt(ui.box.css('left'));
    var top = parseInt(ui.box.css('top'));
    if( left < 0 )
        left = 0;
    if( top < 0 )
        top = 0;
    var area = left+','+top+' ';
    area += ui.box.width()+'x'+ui.box.height();
    area = area.replace(/px/g, '');
    ui.box.remove();
    this.area_box = this.addTagBox(area,this.mask_tags);
    if( this.mask_tags ) {
        this.html.find('.tag_value input').focus();
    } else {
        this.html.find('.tag_key input').focus();
    }

    this.html.find('.tag_area input').attr('value',area);
}

OSVTaggingArea.prototype.show = function( photos, callback ) {
    // Call this so that we call the callback on any
    // existing photos
    this.hide();
    if( photos.length ) {
        this.photos = photos;
        this.callback = photos
        this.showPhoto(0);
        this.html.show();
        if( this.mask_tags ) {
            this.html.find('.tag_value input').focus();
        } else {
            this.html.find('.tag_key input').focus();
        }
    }
}

OSVTaggingArea.prototype.clearTagForm = function() {
    this.html.find('input').attr('value','');
    if( this.mask_tags ) {
        this.html.find('.tag_key input').attr({'value':'mask'})
    }
}

OSVTaggingArea.prototype.changePhoto = function( change ) {
    var new_index = this.current_photo + change;
    if( new_index < 0 )
        new_index = 0;
    if( new_index >= this.photos.length ) {
        //new_index = this.photos.length - 1;
        this.hide();
        return;
    }
    this.showPhoto(new_index);
}

OSVTaggingArea.prototype.showPhoto = function( index ) {
    var p = this.photos[index];
    this.current_photo = index;
    this.photo_html.css('visibility','hidden');
    this.photo_html.attr('src',p.url('large')+"?"+Math.random());
    this.tags_tbody.empty();
    this.clearTagForm();
    this.html.find('.photo_holder .mask').remove();
    var c = 1;
    if( p.data.tags ) {
        for( var i = 0, l = p.data.tags.length; i < l; ++i ) {
            var t = p.data.tags[i];
            this.tags_tbody.append(
                this.createTagHTML(t,false, c) );
            ++c;
        }
    }
    if( p.change_data.tags ) {
        for( var i = 0, l = p.change_data.tags.length; i < l; ++i ) {
            var t = p.change_data.tags[i];
            if( t.area && t.area != '' ) {
                t.area_box = this.addTagBox(t.area,t.mask_tag);
            }
            this.tags_tbody.append(
                this.createTagHTML(t,true, c) );
            ++c;
        }
    }
}

OSVTaggingArea.prototype.createTagHTML = function(t,is_new,odd_even) {
    var tr = document.createElement('tr');
    tr.className = (odd_even % 2 == 1 ) ? 'odd' : 'even';

    var td = document.createElement('td');
    tr.appendChild(td);
    $(td).text(t.key);

    td = document.createElement('td');
    tr.appendChild(td);
    $(td).text(t.value);

    td = document.createElement('td');
    tr.appendChild(td);
    if( t.area ) {
        $(td).text(t.area);
    } else {
        $(td).html('<i>- None -</i>');
    }

    td = document.createElement('td');
    tr.appendChild(td);
    var a = document.createElement('a');
    td.appendChild(a);
    a.href = 'javascript:void(0)';
    a.appendChild(document.createTextNode('Delete'));
    var me = this;
    a.onclick = function() {
        me.removeTag(t,tr);
    }
    return tr;
}

OSVTaggingArea.prototype.removeTag = function(t,tr) {
    tr = $(tr);
    if( tr.hasClass('deleted') ) {
        this.photos[this.current_photo].addTag(t);
        tr.removeClass('deleted');
    } else {
        this.photos[this.current_photo].removeTag(t);
        if( t.is_new ) {
            tr.remove();
        } else {
            tr.addClass('deleted');
        }
    }
}

OSVTaggingArea.prototype.hide = function() {
    if( this.photos && typeof(this.callback) == 'function' ) {
        this.callback(this.photos);
    }
    this.photos = null;
    this.callback = null;
    this.html.hide();
}
