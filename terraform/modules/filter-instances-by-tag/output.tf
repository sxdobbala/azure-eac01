output "filtered_instances" {
  value = ["${compact(split(",",data.external.filter_instances_by_tag.result["filtered_instances_by_tags"]))}"]
}
