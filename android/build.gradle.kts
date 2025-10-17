import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
	if (name == "flutter_vpn") {
		plugins.withId("com.android.library") {
			extensions.configure(LibraryExtension::class.java) {
				val manifestPackage = runCatching {
					val manifestFile = sourceSets.getByName("main").manifest.srcFile
					if (manifestFile.exists()) {
						val content = manifestFile.readText()
						val regex = Regex("package\\s*=\\s*\"([^\"]+)\"")
						regex.find(content)?.groupValues?.getOrNull(1)
					} else {
						null
					}
				}.getOrNull()

				namespace = manifestPackage ?: "com.github.flutter_vpn"
			}
		}
	}
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
