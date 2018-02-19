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
    public class GraphUIApp : Gtk.Application {
        public string CACHE_FOLDER { get; private set; }
        public string AUTOSAVE_FILE { get; private set; }

        static GraphUIApp _instance = null;
        public static GraphUIApp instance {
            get {
                if (_instance == null) {
                    _instance = new GraphUIApp ();
                }
                return _instance;
            }
        }

        construct {
            this.flags |= GLib.ApplicationFlags.HANDLES_OPEN;
            this.application_id = "com.github.artemanufrij.graphui";
            create_cache_folder ();

            var action_open = new SimpleAction ("open", null);
            add_action (action_open);
            add_accelerator ("<Control>o", "app.open", null);
            action_open.activate.connect (
                () => {
                    if (mainwindow != null) {
                        mainwindow.open_file_action ();
                    }
                });

            var action_save = new SimpleAction ("save", null);
            add_action (action_save);
            add_accelerator ("<Control>s", "app.save", null);
            action_save.activate.connect (
                () => {
                    if (mainwindow != null) {
                        mainwindow.save_file_action ();
                    }
                });

            var action_new = new SimpleAction ("new", null);
            add_action (action_new);
            add_accelerator ("<Control>n", "app.new", null);
            action_new.activate.connect (
                () => {
                    if (mainwindow != null) {
                        mainwindow.new_file_action ();
                    }
                });

            var action_compile = new SimpleAction ("compile", null);
            add_action (action_compile);
            add_accelerator ("F5", "app.compile", null);
            action_compile.activate.connect (
                () => {
                    if (mainwindow != null) {
                        mainwindow.create_preview ();
                    }
                });
        }

        public void create_cache_folder () {
            CACHE_FOLDER = GLib.Path.build_filename (GLib.Environment.get_user_cache_dir (), this.application_id);
            try {
                File file = File.new_for_path (CACHE_FOLDER);
                if (!file.query_exists ()) {
                    file.make_directory ();
                }

                AUTOSAVE_FILE = GLib.Path.build_filename (CACHE_FOLDER, "autosave.gv");
            } catch (Error e) {
                warning (e.message);
            }
        }

        MainWindow mainwindow;

        protected override void activate () {
            if (mainwindow != null) {
                mainwindow.present ();
                return;
            }

            mainwindow = new MainWindow ();
            mainwindow.set_application (this);
        }

        public override void open (File[] files, string hint) {
            activate ();
            if (files [0].query_exists ()) {
                mainwindow.current_file = files [0];
                mainwindow.read_file_content (files [0]);
            }
        }
    }
}

public static int main (string [] args) {
    Gtk.init (ref args);
    var app = GraphUI.GraphUIApp.instance;
    return app.run (args);
}
