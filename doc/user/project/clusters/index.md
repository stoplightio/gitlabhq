# Connecting GitLab with a Kubernetes cluster

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/35954) in 10.1.

CAUTION: **Warning:**
The Cluster integration is currently in **Beta**.

With a cluster associated to your project, you can use Review Apps, deploy your
applications, run your pipelines, and much more, in an easy way.

Connect your project to Google Kubernetes Engine (GKE) or your own Kubernetes
cluster in a few steps.

NOTE: **Note:**
The Cluster integration will eventually supersede the
[Kubernetes integration](../integrations/kubernetes.md). For the moment,
you can create only one cluster.

## Prerequisites

In order to be able to manage your GKE cluster through GitLab, the following
prerequisites must be met:

- The [Google authentication integration](../../../integration/google.md) must
  be enabled in GitLab at the instance level. If that's not the case, ask your
  administrator to enable it.
- Your associated Google account must have the right privileges to manage
  clusters on GKE. That would mean that a
  [billing account](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
  must be set up.
- You must have Master [permissions] in order to be able to access the **Cluster**
  page.

If all of the above requirements are met, you can proceed to add a new GKE
cluster.

## Adding a cluster

NOTE: **Note:**
You need Master [permissions] and above to add a cluster.

There are two options when adding a new cluster; either use Google Kubernetes
Engine (GKE) or provide the credentials to your own Kubernetes cluster.

To add a new cluster:

1. Navigate to your project's **CI/CD > Cluster** page
1. If you want to let GitLab create a cluster on GKE for you, go through the
   following steps, otherwise skip to the next one.
    1. Click on **Create with GKE**
    1. Connect your Google account if you haven't done already by clicking the
       **Sign in with Google** button
    1. Fill in the requested values:
      - **Cluster name** (required) - The name you wish to give the cluster.
      - **GCP project ID** (required) - The ID of the project you created in your GCP
        console that will host the Kubernetes cluster. This must **not** be confused
        with the project name. Learn more about [Google Cloud Platform projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).
      - **Zone** - The [zone](https://cloud.google.com/compute/docs/regions-zones/)
        under which the cluster will be created.
      - **Number of nodes** - The number of nodes you wish the cluster to have.
      - **Machine type** - The [machine type](https://cloud.google.com/compute/docs/machine-types)
        of the Virtual Machine instance that the cluster will be based on.
      - **Project namespace** - The unique namespace for this project. By default you
        don't have to fill it in; by leaving it blank, GitLab will create one for you.
1. If you want to use your own existing Kubernetes cluster, click on
   **Add an existing cluster** and fill in the details as described in the
   [Kubernetes integration](../integrations/kubernetes.md) documentation.
1. Finally, click the **Create cluster** button

After a few moments, your cluster should be created. If something goes wrong,
you will be notified.

You can now proceed to install some pre-defined applications and then
enable the Cluster integration.

## Installing applications

GitLab provides a one-click install for various applications which will be
added directly to your configured cluster. Those applications are needed for
[Review Apps](../../../ci/review_apps/index.md) and [deployments](../../../ci/environments.md).

| Application | GitLab version | Description |
| ----------- | :------------: | ----------- |
| [Helm Tiller](https://docs.helm.sh/) | 10.2+ | Helm is a package manager for Kubernetes and is required to install all the other applications. It will be automatically installed as a dependency when you try to install a different app. It is installed in its own pod inside the cluster which can run the `helm` CLI in a safe environment. |
| [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) | 10.2+ | Ingress can provide load balancing, SSL termination, and name-based virtual hosting. It acts as a web proxy for your applications and is useful if you want to use [Auto DevOps](../../../topics/autodevops/index.md) or deploy your own web apps. |

## Enabling or disabling the Cluster integration

After you have successfully added your cluster information, you can enable the
Cluster integration:

1. Click the "Enabled/Disabled" switch
1. Hit **Save** for the changes to take effect

You can now start using your Kubernetes cluster for your deployments.

To disable the Cluster integration, follow the same procedure.

## Removing the Cluster integration

NOTE: **Note:**
You need Master [permissions] and above to remove a cluster integration.

NOTE: **Note:**
When you remove a cluster, you only remove its relation to GitLab, not the
cluster itself. To remove the cluster, you can do so by visiting the GKE
dashboard or using `kubectl`.

To remove the Cluster integration from your project, simply click on the
**Remove integration** button. You will then be able to follow the procedure
and [add a cluster](#adding-a-cluster) again.

[permissions]: ../../permissions.md
