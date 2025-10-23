#!/usr/bin/env python3
import kopf
import kubernetes
from kubernetes.client import V1Deployment, V1DeploymentSpec, V1PodTemplateSpec, V1PodSpec, V1Container, V1ServicePort
from kubernetes.client import V1Service, V1ServiceSpec, V1PersistentVolume, V1PersistentVolumeClaim
from kubernetes.client import V1ObjectMeta, V1EnvVar, V1VolumeMount, V1Volume, V1PersistentVolumeClaimVolumeSource
from kubernetes.client import V1ResourceRequirements, V1Quantity
from kubernetes.client import meta_v1
from kubernetes import config
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load Kubernetes config
config.load_incluster_config()
api_instance = kubernetes.client.AppsV1Api()
core_api = kubernetes.client.CoreV1Api()


@kopf.on.event('otus.homework', 'v1', 'mysqls')
def mysql_handler(event, **kwargs):
    """Handle MySQL CRD events"""
    obj = event['object']
    operation = event['type']
    
    if operation == 'ADDED' or operation == 'MODIFIED':
        create_mysql_resources(obj)
    elif operation == 'DELETED':
        delete_mysql_resources(obj)


def create_mysql_resources(mysql_obj):
    """Create Deployment, Service, PV, PVC for MySQL"""
    name = mysql_obj['metadata']['name']
    namespace = mysql_obj['metadata'].get('namespace', 'default')
    spec = mysql_obj['spec']
    
    image = spec.get('image', 'mysql:5.7')
    database = spec.get('database', 'testdb')
    password = spec.get('password', 'password')
    storage_size = spec.get('storage_size', '1Gi')
    
    logger.info(f"Creating MySQL resources for {namespace}/{name}")
    
    try:
        # 1. Create PersistentVolume
        create_pv(name, namespace, storage_size)
        
        # 2. Create PersistentVolumeClaim
        create_pvc(name, namespace, storage_size)
        
        # 3. Create Service
        create_service(name, namespace)
        
        # 4. Create Deployment
        create_deployment(name, namespace, image, database, password, storage_size)
        
        logger.info(f"MySQL resources created successfully for {namespace}/{name}")
        
    except Exception as e:
        logger.error(f"Error creating MySQL resources: {e}")
        raise


def delete_mysql_resources(mysql_obj):
    """Delete Deployment, Service, PV, PVC for MySQL"""
    name = mysql_obj['metadata']['name']
    namespace = mysql_obj['metadata'].get('namespace', 'default')
    
    logger.info(f"Deleting MySQL resources for {namespace}/{name}")
    
    try:
        # Delete Deployment
        try:
            api_instance.delete_namespaced_deployment(
                name=name,
                namespace=namespace,
                body=kubernetes.client.V1DeleteOptions(propagation_policy='Foreground')
            )
            logger.info(f"Deleted deployment {name}")
        except kubernetes.client.rest.ApiException as e:
            if e.status != 404:
                raise
        
        # Delete Service
        try:
            core_api.delete_namespaced_service(
                name=name,
                namespace=namespace
            )
            logger.info(f"Deleted service {name}")
        except kubernetes.client.rest.ApiException as e:
            if e.status != 404:
                raise
        
        # Delete PersistentVolumeClaim
        try:
            core_api.delete_namespaced_persistent_volume_claim(
                name=f"{name}-pvc",
                namespace=namespace
            )
            logger.info(f"Deleted pvc {name}-pvc")
        except kubernetes.client.rest.ApiException as e:
            if e.status != 404:
                raise
        
        # Delete PersistentVolume
        try:
            core_api.delete_persistent_volume(name=f"{name}-pv")
            logger.info(f"Deleted pv {name}-pv")
        except kubernetes.client.rest.ApiException as e:
            if e.status != 404:
                raise
        
        logger.info(f"MySQL resources deleted successfully for {namespace}/{name}")
        
    except Exception as e:
        logger.error(f"Error deleting MySQL resources: {e}")
        raise


def create_pv(name, namespace, size):
    """Create PersistentVolume"""
    pv_name = f"{name}-pv"
    
    pv = V1PersistentVolume(
        metadata=V1ObjectMeta(name=pv_name),
        spec=kubernetes.client.V1PersistentVolumeSpec(
            capacity={"storage": size},
            access_modes=["ReadWriteOnce"],
            reclaim_policy="Retain",
            storage_class_name="standard",
            host_path=kubernetes.client.V1HostPathVolumeSource(
                path=f"/mnt/data/{namespace}/{name}"
            )
        )
    )
    
    try:
        core_api.create_persistent_volume(pv)
        logger.info(f"Created PV: {pv_name}")
    except kubernetes.client.rest.ApiException as e:
        if e.status == 409:  # Already exists
            logger.info(f"PV {pv_name} already exists")
        else:
            raise


def create_pvc(name, namespace, size):
    """Create PersistentVolumeClaim"""
    pvc_name = f"{name}-pvc"
    pv_name = f"{name}-pv"
    
    pvc = V1PersistentVolumeClaim(
        metadata=V1ObjectMeta(name=pvc_name),
        spec=kubernetes.client.V1PersistentVolumeClaimSpec(
            access_modes=["ReadWriteOnce"],
            storage_class_name="standard",
            resources=V1ResourceRequirements(requests={"storage": size}),
            selector=meta_v1.V1LabelSelector(
                match_labels={"pv": pv_name}
            )
        )
    )
    
    try:
        core_api.create_namespaced_persistent_volume_claim(namespace, pvc)
        logger.info(f"Created PVC: {pvc_name}")
    except kubernetes.client.rest.ApiException as e:
        if e.status == 409:  # Already exists
            logger.info(f"PVC {pvc_name} already exists")
        else:
            raise


def create_service(name, namespace):
    """Create Service for MySQL"""
    service = V1Service(
        metadata=V1ObjectMeta(name=name),
        spec=V1ServiceSpec(
            selector={"app": name},
            ports=[V1ServicePort(port=3306, target_port=3306)],
            cluster_ip="None",  # Headless service
            type="ClusterIP"
        )
    )
    
    try:
        core_api.create_namespaced_service(namespace, service)
        logger.info(f"Created Service: {name}")
    except kubernetes.client.rest.ApiException as e:
        if e.status == 409:  # Already exists
            logger.info(f"Service {name} already exists")
        else:
            raise


def create_deployment(name, namespace, image, database, password, storage_size):
    """Create Deployment for MySQL"""
    
    deployment = V1Deployment(
        metadata=V1ObjectMeta(name=name),
        spec=V1DeploymentSpec(
            replicas=1,
            selector=meta_v1.V1LabelSelector(match_labels={"app": name}),
            template=V1PodTemplateSpec(
                metadata=V1ObjectMeta(labels={"app": name}),
                spec=V1PodSpec(
                    containers=[
                        V1Container(
                            name="mysql",
                            image=image,
                            ports=[kubernetes.client.V1ContainerPort(container_port=3306)],
                            env=[
                                V1EnvVar(name="MYSQL_ROOT_PASSWORD", value=password),
                                V1EnvVar(name="MYSQL_DATABASE", value=database),
                            ],
                            volume_mounts=[
                                V1VolumeMount(
                                    name="data",
                                    mount_path="/var/lib/mysql"
                                )
                            ]
                        )
                    ],
                    volumes=[
                        V1Volume(
                            name="data",
                            persistent_volume_claim=V1PersistentVolumeClaimVolumeSource(
                                claim_name=f"{name}-pvc"
                            )
                        )
                    ]
                )
            )
        )
    )
    
    try:
        api_instance.create_namespaced_deployment(namespace, deployment)
        logger.info(f"Created Deployment: {name}")
    except kubernetes.client.rest.ApiException as e:
        if e.status == 409:  # Already exists
            logger.info(f"Deployment {name} already exists")
        else:
            raise


if __name__ == '__main__':
    kopf.run(loglevel=logging.INFO)
