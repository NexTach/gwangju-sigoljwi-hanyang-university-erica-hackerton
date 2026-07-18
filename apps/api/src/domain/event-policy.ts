import type {
  CreateSensorEventRequest,
  EventStatus,
} from "@road-dna/contracts";

export const maximumGpsAccuracyMeters = 25;
export const minimumMovementSpeedMetersPerSecond = 0.25;
export const maximumDropPeak = 22;
export const minimumSeverity = 0.3;

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
