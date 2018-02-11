/*-
 * Copyright (c) 2018 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace GraphUI {
    public class MainWindow : Gtk.Window {
        Services.GraphViz graphviz;

        Gtk.TextView text;
        Gtk.Image image;
        Gtk.ScrolledWindow image_scroll;

        construct {
            graphviz = Services.GraphViz.instance;
            graphviz.image_created.connect (
                () => {
                    image.set_from_file (graphviz.output_image);
                });
            graphviz.error.connect (
                (message) => {
                    image.set_from_icon_name ("dialog-error-symbolic", Gtk.IconSize.DIALOG);
                    image.tooltip_text = message;
                });
        }

        public MainWindow () {
            build_ui ();
        }

        private void build_ui () {
            var headerbar = new Gtk.HeaderBar ();
            headerbar.title = _ ("GraphUI");
            headerbar.show_close_button = true;

            var compile = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            compile.clicked.connect (
                () => {
                    graphviz.create_preview (text.buffer.text, "svg");
                });
            headerbar.pack_start (compile);

            this.set_titlebar (headerbar);

            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

            text = new Gtk.TextView ();
            var text_scroll = new Gtk.ScrolledWindow (null, null);
            text_scroll.add (text);

            image = new Gtk.Image ();
            image_scroll = new Gtk.ScrolledWindow (null, null);
            image_scroll.add (image);

            paned.pack1 (text_scroll, false, false);
            paned.pack2 (image_scroll, false, false);

            this.add (paned);
            this.show_all ();
        }
    }
}
