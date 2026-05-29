import type { Scene } from "./types";

export const defaultScene: Scene = {
  name: "Sample Stage Scene",
  worldSize: { width: 14, depth: 10 },
  stage: {
    origin: { x: 2, y: 1 },
    width: 10,
    depth: 4,
  },
  subjects: [
    { id: "s1", label: "Performer A", position: { x: 4, y: 3 } },
    { id: "s2", label: "Performer B", position: { x: 7, y: 3 } },
    { id: "s3", label: "Performer C", position: { x: 10, y: 3 } },
  ],
  cameras: [
    {
      id: "c1",
      label: "Cam 1",
      position: { x: 3, y: 8 },
      fovDeg: 30,
      range: 7,
      targetSubjectId: "s1",
      intent: "下手の人物のヘッドショット",
    },
    {
      id: "c2",
      label: "Cam 2",
      position: { x: 7, y: 8.5 },
      fovDeg: 40,
      range: 7,
      targetSubjectId: "s2",
      intent: "センターの人物のミドルショット",
    },
    {
      id: "c3",
      label: "Cam 3",
      position: { x: 11, y: 8 },
      fovDeg: 30,
      range: 7,
      targetSubjectId: "s3",
      intent: "上手の人物のヘッドショット",
    },
  ],
  overheads: [
    {
      id: "o1",
      label: "Overhead L",
      position: { x: 4, y: 6.5 },
      coverageRadius: 3,
    },
    {
      id: "o2",
      label: "Overhead R",
      position: { x: 10, y: 6.5 },
      coverageRadius: 3,
    },
  ],
};
