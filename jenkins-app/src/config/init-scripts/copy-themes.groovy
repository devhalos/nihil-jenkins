import java.nio.file.Files
import java.nio.file.StandardCopyOption

File source = new File("/usr/share/jenkins/ref/themes")
File target = new File("/var/jenkins_home/userContent/themes")

if(!target.exists()) {
    target.mkdir()
}

for(String fileName in source.list()) {
    File sourceFile = new File(source, fileName)
    File targetFile = new File(target, fileName)

    Files.copy(sourceFile.toPath(), targetFile.toPath(), StandardCopyOption.REPLACE_EXISTING)
}
