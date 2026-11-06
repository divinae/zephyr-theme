var plasma = getApiVersion(1);

var layout = {
    "serializationFormatVersion": "1",
    "desktops": [
        {
            "applets": [],
            "config": {
                "/": {
                    "formfactor": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            }
        },
        {
            "applets": [],
            "config": {
                "/": {
                    "formfactor": "0",
                    "wallpaperplugin": "org.kde.image"
                }
            }
        }
    ],
    "panels": [
        {
            "alignment": "right",
            "floating": true,
            "height": 1.7777777777777777,
            "hiding": "normal",
            "lengthMode": "fill",
            "location": "left",
            "maximumLength": 30.833333333333332,
            "minimumLength": 4,
            "offset": 27.27777777777778,
            "opacity": "translucent",
            "applets": [
                {
                    "plugin": "org.kde.plasma.panelspacer",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.kickoff",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.panelspacer",
                    "config": {}
                },
                {
                    "plugin": "org.dhruv8sh.kara",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.panelspacer",
                    "config": {}
                },
                {
                    "plugin": "com.dv.glance",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.panelspacer",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.catwalk",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.systemmonitor",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.systemtray",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.eventcalendar",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.shutdownorswitch",
                    "config": {}
                },
                {
                    "plugin": "org.kde.plasma.panelspacer",
                    "config": {}
                }
            ],
            "config": {
                "/": {
                    "formfactor": "3",
                    "wallpaperplugin": "org.kde.image"
                }
            }
        },
        {
            "alignment": "center",
            "floating": true,
            "height": 3.888888888888889,
            "hiding": "autohide",
            "lengthMode": "fit",
            "location": "bottom",
            "maximumLength": 191.11111111111111,
            "minimumLength": 191.11111111111111,
            "offset": 0,
            "opacity": "translucent",
            "applets": [
                {
                    "plugin": "io.github.divinae.taskline",
                    "config": {}
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "wallpaperplugin": "org.kde.image"
                }
            }
        }
    ]
}
;

plasma.loadSerializedLayout(layout);

