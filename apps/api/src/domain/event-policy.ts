import type {
  CreateSensorEventRequest,
  EventStatus,
} from "@road-dna/contracts";

const maximumGpsAccuracyMeters = 25;
const minimumMovementSpeedMetersPerSecond = 0.25;
const maximumDropPeak = 22;
const minimumSeverity = 0.3;

export function classifyEvent(
  event: CreateSensorEventRequest,
): Exclude<EventStatus, "REJECTED_DUPLICATE"> {
  if (event.gpsAccuracy > maximumGpsAccuracyMeters) {
    return "HELD_LOW_GPS_ACCURACY";
  }
  if (
    event.speed !== undefined &&
    event.speed < minimumMovementSpeedMetersPerSecond
  ) {
    return "REJECTED_STATIONARY";
  }
  if (
    event.peakValue >= maximumDropPeak &&
    (event.window?.peakCount ?? 1) <= 1
  ) {
    return "HELD_DROP_PATTERN";
  }
  if (event.severity < minimumSeverity) {
    return "REJECTED_BELOW_THRESHOLD";
  }
  return "ACCEPTED";
}
