def sortedList = Jenkins.instance.pluginManager.plugins.toSorted({ it.getShortName() })

sortedList.each {
    plugin ->
        println("${plugin.getShortName()}:${plugin.getVersion()}")
}