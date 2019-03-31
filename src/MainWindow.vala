/*-
 * Copyright (c) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
        Settings settings;

        public File ? current_file {get; set; default = null; }

        Gtk.HeaderBar headerbar;
        Gtk.SourceView text;
        Gtk.Image image;
        Gtk.ScrolledWindow image_scroll;
        Gtk.ComboBoxText format_chooser;
        Gtk.Stack stack;
        Gtk.MenuButton app_menu;
        Granite.Widgets.AlertView alert_view;

        construct {
            settings = Settings.get_default ();
            settings.notify["use-dark-theme"].connect (() => {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
            });

            graphviz = Services.GraphViz.instance;
            graphviz.image_created.connect (() => {
                image.set_from_file (graphviz.output_image);
                stack.visible_child_name = "image";
                alert_view.description = "";
            });
            graphviz.error.connect ((message) => {
                image.set_from_file (null);
                stack.visible_child_name = "alert";
                alert_view.title = _ ("Error");
                alert_view.description = message;
                alert_view.icon_name = "dialog-error-symbolic";
            });
        }

        public MainWindow () {
            load_settings ();
            build_ui ();
            this.delete_event.connect (() => {
                if (settings.auto_save_on_close && text.buffer.text.strip ().length > 0) {
                    save_file_action (true);
                }

                save_settings ();
                return false;
            });
        }

        private void build_ui () {
            this.width_request = 1000;
            this.height_request = 600;

            headerbar = new Gtk.HeaderBar ();
            headerbar.title = _ ("GraphUI");
            headerbar.show_close_button = true;

            app_menu = new Gtk.MenuButton ();
            app_menu.valign = Gtk.Align.CENTER;
            app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));

            var settings_menu = new Gtk.Menu ();

            var menu_item_preferences = new Gtk.MenuItem.with_label (_ ("Preferences"));
            menu_item_preferences.activate.connect (() => {
                var preferences = new Dialogs.Preferences (this);
                preferences.run ();
            });

            var menu_item_export = new Gtk.MenuItem.with_label (_ ("Export"));
            menu_item_export.activate.connect (() => {
                export_action ();
            });

            settings_menu.append (menu_item_export);
            settings_menu.append (new Gtk.SeparatorMenuItem ());
            settings_menu.append (menu_item_preferences);
            settings_menu.show_all ();

            app_menu.popup = settings_menu;
            headerbar.pack_end (app_menu);

            header_build_style_switcher ();

            var new_file = new Gtk.Button.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
            new_file.clicked.connect (new_file_action);
            new_file.tooltip_text = _ ("New File");
            headerbar.pack_start (new_file);

            var open_file = new Gtk.Button.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR);
            open_file.clicked.connect (open_file_action);
            open_file.tooltip_text = _ ("Open File");
            headerbar.pack_start (open_file);

            var save_as = new Gtk.Button.from_icon_name ("document-save-as", Gtk.IconSize.LARGE_TOOLBAR);
            save_as.clicked.connect (() => {
                save_file_action ();
            });
            save_as.tooltip_text = _ ("Save File");
            headerbar.pack_start (save_as);

            var compile = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            compile.tooltip_text = _ ("Compile [F5]");
            compile.clicked.connect (() => {
                create_preview ();
            });
            headerbar.pack_end (compile);

            format_chooser = new Gtk.ComboBoxText ();
            format_chooser.append ("dot", "dot");
            format_chooser.append ("neato", "neato");
            format_chooser.append ("fdp", "fdp");
            format_chooser.append ("sfdp", "sfdp");
            format_chooser.append ("twopi", "twopi");
            format_chooser.active_id = "dot";
            format_chooser.tooltip_text = _ ("Type");
            format_chooser.valign = Gtk.Align.CENTER;
            format_chooser.changed.connect (() => {
                create_preview ();
            });

            headerbar.pack_end (format_chooser);

            this.set_titlebar (headerbar);

            var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

            text = new Gtk.SourceView ();
            text.top_margin = text.left_margin = text.bottom_margin = text.right_margin = 12;
            var text_scroll = new Gtk.ScrolledWindow (null, null);

            text_scroll.add (text);

            image = new Gtk.Image ();

            alert_view = new Granite.Widgets.AlertView (_ ("Graph Visualization"), _ ("Represent structural information as diagrams of abstract graphs and networks"), "edit");

            stack = new Gtk.Stack ();
            stack.add_named (alert_view, "alert");
            stack.add_named (image, "image");

            image_scroll = new Gtk.ScrolledWindow (null, null);
            image_scroll.add (stack);

            paned.pack1 (text_scroll, false, false);
            paned.pack2 (image_scroll, false, false);

            this.add (paned);
            this.show_all ();

            check_for_autosave ();
        }

        private void header_build_style_switcher () {
            var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
            mode_switch.valign = Gtk.Align.CENTER;
            mode_switch.active = settings.use_dark_theme;
            mode_switch.notify["active"].connect (() => {
                settings.use_dark_theme = mode_switch.active;
            });
            headerbar.pack_end (mode_switch);
        }

        public void create_preview (bool save = true) {
            var graph_text = text.buffer.text.strip ();
            if (graph_text.length == 0) {
                return;
            }

            if (save && current_file != null) {
                save_file_action ();
            }

            graphviz.create_preview (graph_text, format_chooser.active_id, "png", current_file);
        }

        public void check_for_autosave () {
            var file = File.new_for_path (GraphUIApp.instance.AUTOSAVE_FILE);

            if (file.query_exists ()) {
                read_file_content (file);
                file.delete_async.begin ();
            }
        }

        public void open_file_action () {
            var file_dialog = new Gtk.FileChooserDialog (
                _ ("Choose an graphviz file…"),
                this,
                Gtk.FileChooserAction.OPEN,
                _ ("_Cancel"), Gtk.ResponseType.CANCEL,
                _ ("_Open"), Gtk.ResponseType.ACCEPT);

            var filter = new Gtk.FileFilter ();
            filter.set_filter_name (_ ("Graphviz"));
            filter.add_mime_type ("text/vnd.graphviz");

            file_dialog.add_filter (filter);

            if (file_dialog.run () != Gtk.ResponseType.ACCEPT) {
                current_file.dispose ();
                return;
            }
            var filname = file_dialog.get_filename ();
            file_dialog.destroy ();

            current_file = File.new_for_path (filname);
            read_file_content (current_file);
        }

        public void read_file_content (File file) {
            text.buffer.text = "";
            try {
                string content = "";
                FileUtils.get_contents (file.get_path (), out content);
                text.buffer.text = content;
                headerbar.title = file.get_basename ();
            } catch (Error err) {
                warning (err.message);
            }

            create_preview ();
        }

        public void new_file_action () {
            current_file = null;
            image.set_from_file (null);
            headerbar.title = _ ("GraphUI");
            text.buffer.text = "";
            text.grab_focus ();
        }

        public void save_file_action (bool closing=false) {
            if (current_file == null && closing) {
                current_file = File.new_for_path (GraphUIApp.instance.AUTOSAVE_FILE);
            }

            if (current_file == null) {
                var file_dialog = new Gtk.FileChooserDialog (
                    _ ("Save as…"), this,
                    Gtk.FileChooserAction.SAVE,
                    _ ("Cancel"), Gtk.ResponseType.CANCEL,
                    _ ("Save"), Gtk.ResponseType.ACCEPT);

                file_dialog.set_current_name (_ ("New Graphviz.gv"));

                var filter = new Gtk.FileFilter ();
                filter.set_filter_name ("Graphviz");
                filter.add_mime_type ("text/vnd.graphviz");

                file_dialog.add_filter (filter);

                if (file_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    var filename = file_dialog.get_filename ();
                    current_file.dispose ();
                    current_file = File.new_for_path (filename);
                }
                file_dialog.destroy ();

                if (current_file == null) {
                    return;
                }
            }

            try {
                FileUtils.set_contents (current_file.get_path (), text.buffer.text);
                create_preview (false);
            } catch (Error err) {
                warning (err.message);
                return;
            }

            headerbar.title = current_file.get_basename ();
        }

        private void export_action () {
            var file_dialog = new Gtk.FileChooserDialog (
                _ ("Save as…"), this,
                Gtk.FileChooserAction.SAVE,
                _ ("Cancel"), Gtk.ResponseType.CANCEL,
                _ ("Save"), Gtk.ResponseType.ACCEPT);

            if (current_file != null) {
                file_dialog.set_current_name (Utils.strip_filename (current_file.get_basename ()));
            } else {
                file_dialog.set_current_name (_ ("Export"));
            }

            var filter_png = new Gtk.FileFilter ();
            filter_png.set_filter_name ("png");
            filter_png.add_mime_type ("image/png");

            var filter_svg = new Gtk.FileFilter ();
            filter_svg.set_filter_name ("svg");
            filter_svg.add_mime_type ("image/svg+xml");

            file_dialog.add_filter (filter_png);
            file_dialog.add_filter (filter_svg);

            if (file_dialog.run () == Gtk.ResponseType.ACCEPT) {
                var filename = file_dialog.get_filename ();
                if (!filename.down ().has_suffix (file_dialog.filter.get_filter_name ())) {
                    filename += "." + file_dialog.filter.get_filter_name ();
                }
                graphviz.export (filename, text.buffer.text, format_chooser.active_id);
            }
            file_dialog.destroy ();
        }

        private void load_settings () {
            this.set_default_size (settings.window_width, settings.window_height);

            if (settings.window_x < 0 || settings.window_y < 0 ) {
                this.window_position = Gtk.WindowPosition.CENTER;
            } else {
                this.move (settings.window_x, settings.window_y);
            }

            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
        }

        private void save_settings () {
            int x, y;
            this.get_position (out x, out y);
            settings.window_x = x;
            settings.window_y = y;

            int width, height;
            this.get_size (out width, out height);
            settings.window_height = height;
            settings.window_width = width;
        }
    }
}
