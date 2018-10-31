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

        private GraphViz () {
        }

        public void export (string path, string content, string format, File ? file = null) {
            if (!path.down ().has_suffix ("svg")) {
                create_preview (content, format, "png", file);
            } else {
                create_preview (content, format, "svg", file);
            }

            var file_dst = File.new_for_path (path);
            var file_src = File.new_for_path (output_image);
            file_src.copy_async.begin (file_dst, GLib.FileCopyFlags.OVERWRITE);

            file_dst.dispose ();
            file_src.dispose ();
        }

        public void create_preview (string content, string format = "dot", string type = "png", File ? file = null) {
            if (file == null && !create_tmp_file (content)) {
                return;
            }

            var work_dir = GraphUIApp.instance.CACHE_FOLDER;

            if (file != null) {
                output_txt = file.get_path ();
                work_dir = file.get_parent ().get_path ();
            } else {
                output_txt = GraphUIApp.instance.CACHE_FOLDER + "/output.txt";
            }
            output_image = GraphUIApp.instance.CACHE_FOLDER + "/output.svg";

            string[] spawn_args = {format, "-T%s".printf (type), "%s".printf (output_txt), "-o", "%s".printf (output_image)};
            string[] spawn_env = Environ.get ();

            string processout = "";
            string stderr = "";
            int status = 0;

            try {
                Process.spawn_sync (
                    work_dir,
                    spawn_args,
                    spawn_env,
                    SpawnFlags.SEARCH_PATH,
                    null,
                    out processout,
                    out stderr,
                    out status);
            } catch (SpawnError e) {
                error (e.message);
                return;
            }

            if (stderr != "") {
                error (stderr.replace (output_txt + ": ", "").strip ());
                return;
            }

            image_created ();
        }

        private bool create_tmp_file (string content) {
            try {
                FileUtils.set_contents (output_txt, content);
                return true;
            } catch (Error err) {
                warning (err.message);
            }

            return false;
        }
    }
}
