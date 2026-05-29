export interface Coord {
  x: number;
  y: number;
}

export interface Stage {
  origin: Coord;
  width: number;
  depth: number;
}

export interface Subject {
  id: string;
  label: string;
  position: Coord;
}

export interface Camera {
  id: string;
  label: string;
  position: Coord;
  fovDeg: number;
  range: number;
  targetSubjectId: string | null;
  intent: string;
}

export interface OverheadCamera {
  id: string;
  label: string;
  position: Coord;
  coverageRadius: number;
}

export interface Scene {
  name: string;
  worldSize: { width: number; depth: number };
  stage: Stage;
  subjects: Subject[];
  cameras: Camera[];
  overheads: OverheadCamera[];
}
