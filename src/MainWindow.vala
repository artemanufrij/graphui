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

        File ? current_file = null;

        Gtk.TextView text;
        Gtk.Image image;
        Gtk.ScrolledWindow image_scroll;
        Gtk.ComboBoxText format_chooser;

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
            this.width_request = 800;
            this.height_request = 600;

            var headerbar = new Gtk.HeaderBar ();
            headerbar.title = _ ("GraphUI");
            headerbar.show_close_button = true;

            var new_file = new Gtk.Button.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
            new_file.clicked.connect (new_file_action);
            headerbar.pack_start (new_file);

            var open_file = new Gtk.Button.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR);
            open_file.clicked.connect (open_file_action);
            headerbar.pack_start (open_file);

            var save_as = new Gtk.Button.from_icon_name ("document-save-as", Gtk.IconSize.LARGE_TOOLBAR);
            save_as.clicked.connect (save_file_action);
            headerbar.pack_start (save_as);

            var compile = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            compile.clicked.connect (create_preview);
            headerbar.pack_end (compile);

            format_chooser = new Gtk.ComboBoxText ();
            format_chooser.append ("svg", ".svg");
            format_chooser.append ("sng", ".png");
            format_chooser.active_id = "svg";
            format_chooser.tooltip_text = _ ("Format");
            format_chooser.valign = Gtk.Align.CENTER;
            format_chooser.changed.connect (create_preview);

            headerbar.pack_end (format_chooser);

            this.set_titlebar (headerbar);

            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

            text = new Gtk.TextView ();
            text.top_margin = text.left_margin = text.bottom_margin = text.right_margin = 12;
            var text_scroll = new Gtk.ScrolledWindow (null, null);
            text_scroll.expand = true;
            text_scroll.add (text);

            image = new Gtk.Image ();
            image_scroll = new Gtk.ScrolledWindow (null, null);
            image_scroll.add (image);

            paned.pack1 (text_scroll, false, false);
            paned.pack2 (image_scroll, false, false);

            this.add (paned);
            this.show_all ();
        }

        private void create_preview () {
            graphviz.create_preview (text.buffer.text, format_chooser.active_id);
        }

        private void open_file_action () {
            var file_dialog = new Gtk.FileChooserDialog (
                    _ ("Choose an graphviz file…"), this,
                Gtk.FileChooserAction.OPEN,
                    _ ("_Cancel"), Gtk.ResponseType.CANCEL,
                    _ ("_Open"), Gtk.ResponseType.ACCEPT);

            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_ ("Graphviz"));
            filter.add_mime_type ("text/plain");

            file_dialog.add_filter (filter);

            if (file_dialog.run () != Gtk.ResponseType.ACCEPT) {
                current_file.dispose ();
                return;
            }
            var filname = file_dialog.get_filename ();
            file_dialog.destroy ();

            text.buffer.text = "";


            current_file = File.new_for_path (filname);
            DataInputStream dis = new DataInputStream (current_file.read ());
            string line;

            while ((line = dis.read_line ()) != null) {
                text.buffer.text +=line +"\n";
            }

            dis.close ();
            current_file.dispose ();
        }

        private void new_file_action () {
            current_file = null;
            text.buffer.text = "";
        }

        private void save_file_action () {
            if (current_file == null) {
                var file_dialog = new Gtk.FileChooserDialog (
                    _ ("Choose an graphviz file…"), this,
                    Gtk.FileChooserAction.SAVE,
                    Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                    Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);

                var filter = new Gtk.FileFilter ();
                filter.set_filter_name (_ ("Graphviz"));
                filter.add_mime_type ("text/plain");

                if (file_dialog.run () != Gtk.ResponseType.ACCEPT) {
                    current_file.dispose ();
                    return;
                }

                var filname = file_dialog.get_filename ();
                current_file.dispose ();
                current_file = File.new_for_path (filname);
            }
        }
    }
}
