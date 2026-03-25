allprojects {
    buildscript {
        repositories {
            maven { url = uri("https://maven.aliyun.com/repository/google") }
            maven { url = uri("https://maven.aliyun.com/repository/public") }
            google()
            mavenCentral()
        }
        configurations.all {
            resolutionStrategy {
                force("com.android.tools.build:gradle:8.7.3")
                force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
            }
        }
    }
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    
    // 强制子项目使用统一的 Gradle 插件版本，防止 8.13.1 报错
    configurations.all {
        resolutionStrategy {
            force("com.android.tools.build:gradle:8.7.3")
            force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
