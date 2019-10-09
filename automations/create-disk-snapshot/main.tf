# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# 	https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
resource "google_cloudfunctions_function" "create-disk-snapshot" {
  name                  = "SnapshotDisk"
  description           = "Takes a snapshot of a GCE disk."
  runtime               = "go111"
  available_memory_mb   = 128
  source_archive_bucket = "${var.gcf-bucket-name}"
  source_archive_object = "${var.gcf-object-name}"
  timeout               = 60
  project               = "${var.automation-project}"
  region                = "${var.region}"
  entry_point           = "SnapshotDisk"

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = "${var.findings-topic}"
  }
}

# Role "compute.instanceAdmin" required to get disk lists and create snapshots for GCE instances.
# This role can be applied on individual projects, folders or at the organization level.
# This is used in functions/create_snapshot.go which creates new snapshots of the disk in the event
# of certain detectors triggering. These snapshots can help analysis of the event as the disk is
# captured at the time the activity occurred. This binding can be removed if the action is not
# being used.
#
# TODO: Support folder level grants.
resource "google_organization_iam_member" "gce-snapshot-bind-findings-organization" {
  org_id = "${var.organization-id}"
  role   = "roles/compute.instanceAdmin.v1"
  member = "serviceAccount:${var.automation-service-account}"
}
