"use client";

import type { Camera, Scene } from "@/lib/types";

interface Props {
  scene: Scene;
  camera: Camera | null;
}

export function IntentCard({ scene, camera }: Props) {
  if (!camera) {
    return (
      <div className="intent-card empty">
        左の上面図またはリストからカメラを選択すると、撮影意図が表示されます。
      </div>
    );
  }

  const target = scene.subjects.find((s) => s.id === camera.targetSubjectId);
  const distance = target
    ? Math.hypot(
        target.position.x - camera.position.x,
        target.position.y - camera.position.y
      )
    : 0;

  return (
    <div className="intent-card">
      <h3>{camera.label}</h3>
      <dl>
        <dt>担当被写体</dt>
        <dd>{target ? target.label : "未割り当て"}</dd>
        <dt>画角</dt>
        <dd>{camera.fovDeg}°</dd>
        <dt>距離 (シーン単位)</dt>
        <dd>{distance.toFixed(2)}</dd>
        <dt>撮影意図</dt>
        <dd>{camera.intent}</dd>
      </dl>
    </div>
  );
}
