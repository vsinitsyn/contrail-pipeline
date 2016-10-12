/**
 *
 * contrail build, test, promote pipeline
 *
 * Expected parameters:
 *   ARTIFACTORY_URL        Artifactory server location
 *   ARTIFACTORY_OUT_REPO   local repository name to upload image
 *   OS                     distribution name to build for (debian, ubuntu, etc.)
 *   DIST                   distribution version (jessie, trusty)
 *   ARCH                   comma-separated list of architectures to build
 *   FORCE_BUILD            Force build even when image exists
 *   BUILD_DPDK             Build dpdk-enabled vrouter
 *   DPDK_VERSION           DPDK version to fetch
 *   PROMOTE_ENV            Environment for promotion (default "stable")
 *   KEEP_REPOS             Always keep input repositories even on failure
 *   SOURCE_URL             URL to source code base (component names will be
 *                          appended)
 *   SOURCE_BRANCH          Branch of opencontrail to build
 *   SOURCE_CREDENTIALS     Credentials to use to checkout source
 *   PIPELINE_LIBS_URL      URL to git repo with shared pipeline libs
 *   PIPELINE_LIBS_BRANCH   Branch of pipeline libs repo
 *   PIPELINE_LIBS_CREDENTIALS_ID   Credentials ID to use to access shared
 *                                  libs repo
 */

// Load shared libs
def common, artifactory
fileLoader.withGit(PIPELINE_LIBS_URL, PIPELINE_LIBS_BRANCH, PIPELINE_LIBS_CREDENTIALS_ID, '') {
    common = fileLoader.load("common");
    artifactory = fileLoader.load("artifactory");
}

// Define global variables
def timestamp = common.getDatetime()

def components = [
    ["contrail-build", "tools/build"],
    ["contrail-controller", "controller"],
    ["contrail-vrouter", "vrouter"],
    ["contrail-third-party", "third_party"],
    ["contrail-generateDS", "tools/generateds"],
    ["contrail-sandesh", "tools/sandesh"],
    ["contrail-packages", "tools/packages"],
    ["contrail-nova-vif-driver", "openstack/nova_contrail_vif"],
    ["contrail-neutron-plugin", "openstack/neutron_plugin"],
    ["contrail-nova-extensions", "openstack/nova_extensions"],
    ["contrail-heat", "openstack/contrail-heat"],
    ["contrail-ceilometer-plugin", "openstack/ceilometer_plugin"],
    ["contrail-web-storage", "contrail-web-storage"],
    ["contrail-web-server-manager", "contrail-web-server-manager"],
    ["contrail-web-controller", "contrail-web-controller"],
    ["contrail-web-core", "contrail-web-core"],
    ["contrail-webui-third-party", "contrail-webui-third-party"]
]

def inRepos = [
    "generic": [
        "in-dockerhub"
    ],
    "debian": [
        "in-debian",
        "in-debian-security"
    ],
    "ubuntu": [
        "in-ubuntu"
    ]
]

def art = artifactory.connection(
    ARTIFACTORY_URL,
    null,
    false,
    ARTIFACTORY_OUT_REPO
)

def git_commit = [:]
def properties = [:]

node('docker') {
    checkout scm
    git_commit['contrail-pipeline'] = common.getGitCommit()

    stage("checkout") {
        gitCheckoutSteps = [:]
        for (component in components) {
            gitCheckoutSteps[component[0]] = common.gitCheckoutStep(
                "src/${component[1]}",
                "${SOURCE_URL}/${component[0]}.git",
                SOURCE_BRANCH,
                SOURCE_CREDENTIALS,
                true,
                true
            )
        }
        parallel gitCheckoutSteps

        for (component in components) {
            dir("src/${component[1]}") {
                commit = common.getGitCommit()
                git_commit[component[0]] = commit
                properties["git_commit_"+component[0].replace('-', '_')] = commit
            }
        }

        sh("ln -s src/tools/build/SConstruct src/SConstruct")
        sh("ln -s src/tools/packages/packages.make src/packages.make")

        if (BUILD_DPDK.toBoolean() == true) {
            sh("wget --no-check-certificate -O - ${art.url}/in-dpdk/dpdk-${DPDK_VERSION}.tar.xz | tar xJf -; mv dpdk-* dpdk")
        }
    }

    // Check if image of this commit hash isn't already built
    def results = artifactory.findArtifactByProperties(
        art,
        properties,
        art.outRepo
    )
    if (results.size() > 0) {
        println "There are already ${results.size} artefacts with same git commits"
        if (FORCE_BUILD.toBoolean() == false) {
            common.abortBuild()
        }
    }

    stage("prepare") {
        // Prepare Artifactory repositories
        out = artifactory.createRepos(art, inRepos['generic']+inRepos[OS], timestamp)
        println "Created input repositories: ${out}"
    }

    try {
        stage("build") {
            def imgName = "${OS}-${DIST}-${ARCH}"
            docker.build(
                "${imgName}:${timestamp}",
                [
                    "-f docker/${imgName}.Dockerfile",
                    "docker"
                ].join(' ')
            )

            imgName.inside {
                sh("pushd src/third_party; DIST=${OS} VERSION=${DIST_VERSION} python fetch_packages.py; popd")
                sh("pushd src; make -f packages.make source-all")
            }
        }
    } catch (Exception e) {
        currentBuild.result = 'FAILURE'
        if (KEEP_REPOS.toBoolean() == false) {
            println "Build failed, cleaning up input repositories"
            out = artifactory.deleteRepos(art, inRepos['generic']+inRepos[OS], timestamp)
        }
        throw e
    }

    stage("upload") {
        // TODO: Push to artifactory
    }
}

def promoteEnv = PROMOTE_ENV ? PROMOTE_ENV : "stable"

timeout(time:1, unit:"DAYS") {
    input "Promote to ${promoteEnv}?"
}

node('docker') {
    stage("promote-${promoteEnv}") {
        // TODO: promote
    }
}
