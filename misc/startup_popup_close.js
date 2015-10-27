UIATarget.onAlert = function onAlert(alert) {
    var title = alert.name();
    UIALogger.logWarning("Alert with title '" + title + "' encountered.");
    return true;
}
UIATarget.localTarget().delay(4);
UIATarget.localTarget().frontMostApp().alert().buttons()[0].tap();
