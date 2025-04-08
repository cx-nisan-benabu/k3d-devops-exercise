import jenkins.model.*
import hudson.model.*
import javaposse.jobdsl.plugin.*
import org.csanchez.jenkins.plugins.kubernetes.*
import java.nio.file.*

println "[🌱] Initial job DSL bootstrap process starting..."

Thread.start {
    println "[⏳] Jenkins startup in progress, waiting for services to come online..."
    sleep(30000)  // Allow Jenkins time to settle

    def jenkins = Jenkins.getInstanceOrNull()
    if (jenkins == null) {
        println("[❌] Jenkins instance unavailable. Aborting job DSL init.")
        return
    }

    def seedJobName = "JobDSL-Seed"
    def existingJob = jenkins.getItem(seedJobName)

    if (existingJob != null) {
        println("[✔️] Found existing seed job: '${seedJobName}', skipping creation.")
    } else {
        println("[🛠️] Creating fresh seed job: '${seedJobName}'...")

        def job = jenkins.createProject(FreeStyleProject, seedJobName)
        job.setDisplayName("Seed Job for Kubernetes Worker Pods")

        def dslScriptPath = "/var/jenkins_home/job-dsl.groovy"
        if (!new File(dslScriptPath).exists()) {
            println("[⚠️] DSL script not found at: ${dslScriptPath}. Cannot proceed.")
            return
        }

        def dslScript = new File(dslScriptPath).text

        def dslBuilder = new ExecuteDslScripts()
        dslBuilder.setScriptText(dslScript)
        dslBuilder.setSandbox(true)

        job.buildersList.add(dslBuilder)
        job.save()

        println("[📡] Scheduling first execution of seed job...")
        job.scheduleBuild2(0)

        println("[✅] Seed job '${seedJobName}' initialized and queued.")
    }
}
