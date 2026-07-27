# Intro to Jenkins
- What is CI? Benefits?
    - Continous Integration
    - Often triggered by: A developer pushes their code changes to a shared repository
    - Tests are automatically run on the code before...
    - The tested code is integrated/merged into the main code base
  
- What is CD? Benefits?
  - Means either:
    - Continous Delivery
      - Making sure that the software is always in a deployable state
      - We need code that can be pushed to production at any time (that may take the form of a artifact)
    - Continuous Deployment
      - Does what continuous delivery does, but goes one step further
      - Also deploys the code

- Difference between CD and CDE
- What is Jenkins?
  - Open-source automation server
  - Not just for CI/CD pipelines

- Why use Jenkins? Benefits of using Jenkins? Disadvantages?
  - Benefits
    - Automation
    - Extensible via the plugins
    - Scalability
    - Community support
    - Cross-platform

  - Disadvantages
    - Complex for beginners
    - Maintenance overhead
    - Can be resource-intensive
    - User interface

- Stages of Jenkins

1. Source Code Management (SCM) (Part of CI)
2. Build (Part of CI)
3. Test (Part of CI)
4. Integrate/merge code in main code base (Part of CI)
5. Package (Part of CD)
6. Deploy (If pipeline is doing Continous Deployment)
7. Monitor (If pipeline is doing Continous Deployment)
- What alternatives are there for Jenkins

    - GitHub Actions
    - GitLab
    - Azure DevOps
    - CircleCI
    - Travis CI
    - Bamboo
    - TeamCity
    - GoCD
  
- Why build a pipeline? Business value?

  - Faster to get latest version of product into the hands of the end users (Faster time to market)
  - Faster feedback cycle
  - Improved quality
  - Reduced risk
  - Productivity 

- Create a general diagram of CICD
- Understand SDLC workflow: plan, design, develop, deploy