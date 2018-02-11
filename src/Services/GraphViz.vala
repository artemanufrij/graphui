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
        string output_image = "";

        public signal void image_created ();

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
//            create_tmp_file (content);

            stdout.printf ("test\n");

return;
            var command = ("dot -Tsvg "+output_txt+" -o ~/output.svg");

            stdout.printf ("%s\n", command);
            return;
            string stdout;
            string stderr;
            int status;

            try {
                Process.spawn_command_line_sync (
                    command,
                    out stdout,
                    out stderr,
                    out status
                    );
            } catch (SpawnError e) {
                stdout.printf ("Error: %s\n", e.message);
            }
        }

        private bool create_tmp_file (string content) {
            File file = File.new_for_path (output_txt);
            if (file.query_exists ()) {
                file.delete ();
            }
            FileIOStream ios = file.create_readwrite (FileCreateFlags.PRIVATE);

            FileOutputStream os = ios.output_stream as FileOutputStream;
            os.write (content.data);
            os.close ();
            return true;
        }
    }
}
