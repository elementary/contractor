
using GLib;
[DBus (name = "org.elementary.Contractor")]
interface Demo : Object {
    public abstract string GetServicesByLocation (string strlocation) throws IOError;
     public signal void pong (int count, string msg);
}

void main () {
    var loop = new MainLoop();
    try {
        message("trying");
        Demo demo = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.Contractor", "/org/elementary/contractor");
       demo.pong.connect((m) => {
            stdout.printf ("Got pong for msg '%d'\n", m);
            loop.quit ();
        });

        var contract = demo.GetServicesByLocation ("file:///home/michael/plop.tar");
    } catch (Error e) {
        stderr.printf ("%s\n", e.message);
    }
}

