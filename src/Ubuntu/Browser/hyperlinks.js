/*
 * Copyright 2013 Canonical Ltd.
 *
 * This file is part of ubuntu-browser.
 *
 * ubuntu-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ubuntu-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

var doc = document.documentElement;

doc.addEventListener('click', function(event) {
    var node = event.target;
    while (node) {
        if (node.nodeName.toLowerCase() == 'a') {
            // Using event delegation to work around the lack of support for
            // handling hyperlinks with a target attribute set to '_blank' in
            // QtWebKit. See related upstream bug reports:
            //    https://bugs.webkit.org/show_bug.cgi?id=76416
            //    https://bugs.webkit.org/show_bug.cgi?id=91779
            if (node.hasAttribute('target')) {
                if (node.getAttribute('target').toLowerCase() == '_blank') {
                    window.location = node.getAttribute('href');
                }
            }
            break;
        }
        node = node.parentNode;
    }
});