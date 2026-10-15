import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "my-bmw"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property string vehicleName: setting("vehicleName", "BMW")
  property int batteryLevel: setting("batteryLevel", 80)
  property bool isCharging: setting("isCharging", false)

  function refresh(): void {
    root.broadcast("refresh")
  }

  ShellIpc {
    target: root.moduleName

    function refresh(): void {
      root.refresh()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.vertical ? "" : "BMW " + root.batteryLevel + "%"
    labelVisible: !root.vertical
    tooltipText: root.vehicleName + ": " + root.batteryLevel + "%" + (root.isCharging ? " (Charging)" : "")

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) {
        root.refresh()
      } else {
        if (root.bar && typeof root.bar.run === "function") {
          root.bar.run("omarchy-notification-send 'BMW' 'Battery: " + root.batteryLevel + "%'")
        }
      }
    }
  }
}
