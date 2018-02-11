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

namespace GraphUI.Services {
    public class GraphViz : GLib.Object {
        string output_txt = "";
        public string output_image { get; private set; default = ""; }

        public signal void image_created ();
        public signal void error (string message);

        static GraphViz _instance = null;
        public static GraphViz instance {
            get {
                if (_instance == null) {
                    _instance = new GraphViz ();
                }
                return _instance;
            }
        }

        construct {
            output_txt = GraphUIApp.instance.CACHE_FOLDER + "/output.txt";
            output_image = GraphUIApp.instance.CACHE_FOLDER + "/output.svg";
        }

        private GraphViz () {
        }

        public void create_preview (string content, string format) {
            if (!create_tmp_file (content)) {
                return;
            }

            stdout.printf ("test\n");

            var command = ("dot -Tsvg %s -o %s").printf (output_txt, output_image);

            stdout.printf ("%s\n", command);

            string processout = "";
            string stderr = "";
            int status = 0;

            try {
                Process.spawn_command_line_sync (
                    command,
                    out processout,
                    out stderr,
                    out status
                    );
            } catch (SpawnError e) {
                stdout.printf ("Error: %s\n", e.message);
                error (e.message);
                return;
            }

            if (stderr != "") {
                error (stderr);
                return;
            }

            image_created ();
        }

        private bool create_tmp_file (string content) {
            try {
                File file = File.new_for_path (output_txt);
                if (file.query_exists ()) {
                    file.delete ();
                }
                FileIOStream ios = file.create_readwrite (FileCreateFlags.PRIVATE);

                FileOutputStream os = ios.output_stream as FileOutputStream;
                os.write (content.data);
                os.close ();
                ios.close ();
                file.dispose ();
                return true;
            } catch (Error err) {
                warning (err.message);
            }

            return false;
        }
    }
}
