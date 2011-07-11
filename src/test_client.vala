
[DBus (name = "org.elementary.contractor")]
interface Demo : Object {
    public abstract GLib.HashTable<string,string>[] GetServicesByLocation (string strlocation, string? file_mime="")    throws IOError;
}

void main () {
    try {
        Demo demo = Bus.get_proxy_sync (BusType.SESSION, "org.elementary.contractor",
                                        "/org/elementary/contractor");

        var contracts = demo.GetServicesByLocation ("file:///home/kitkat/plop.tar");
        foreach(var entry in contracts)
        {
            message ("desc: %s icon: %s", entry.lookup ("Description"), entry.lookup ("IconName"));
        }
    } catch (IOError e) {
        stderr.printf ("%s\n", e.message);
    }
}

