multibranchPipelineJob('spring-crud-example-project-management-app') {
    branchSources {
        git {
            id = 'spring-crud-example-project-management-app'
            remote('https://github.com/NItishSh/Spring-CRUD-Example-Project-Management-App.git')
        }
    }
}