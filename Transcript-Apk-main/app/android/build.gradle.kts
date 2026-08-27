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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val action = Action<Project> {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                androidExt::class.java.getMethod("setCompileSdkVersion", Int::class.java).invoke(androidExt, 36)
            } catch (e: Exception) {}
        }
    }
    if (state.executed) {
        action.execute(this)
    } else {
        afterEvaluate(action)
    }
}
