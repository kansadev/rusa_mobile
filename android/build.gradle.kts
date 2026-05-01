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
    plugins.withId("com.android.library") {
        afterEvaluate {
            val androidExt = extensions.findByName("android") ?: return@afterEvaluate
            val getNamespace = androidExt.javaClass.methods.firstOrNull {
                it.name == "getNamespace" && it.parameterCount == 0
            }
            val currentNamespace = getNamespace?.invoke(androidExt) as? String
            if (!currentNamespace.isNullOrBlank()) return@afterEvaluate

            val safeProjectName = project.name
                .replace(Regex("[^A-Za-z0-9_]"), "_")
                .let { if (it.firstOrNull()?.isDigit() == true) "lib_$it" else it }
            val fallbackNamespace = "com.rusa.generated.$safeProjectName"

            val setNamespace = androidExt.javaClass.methods.firstOrNull {
                it.name == "setNamespace" && it.parameterCount == 1
            }
            setNamespace?.invoke(androidExt, fallbackNamespace)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
