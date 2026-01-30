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
    
    // Fix for library projects without namespace
    if (project.name != "app") {
        project.afterEvaluate {
            if (project.plugins.hasPlugin("com.android.library")) {
                project.extensions.getByName("android").apply {
                    (this as? com.android.build.gradle.LibraryExtension)?.apply {
                        if (namespace == null) {
                            namespace = "dummy.namespace"
                        }
                    }
                }
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
