using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(LowResFilter))]
public class LowResFilterEditor : Editor {

	public string[] options = new string[] { "240p", "300p", "480p", "Custom" };
	public int index = 0;

	public override void OnInspectorGUI () {

		LowResFilter myTarget = (LowResFilter)target;

		index = EditorGUILayout.Popup ("Resolution", index, options);

		switch (index) {
		case 0:
			myTarget.verticalResolution = 240;
			break;
		case 1:
			myTarget.verticalResolution = 300;
			break;
		case 2:
			myTarget.verticalResolution = 480;
			break;
		case 3:
			myTarget.verticalResolution = EditorGUILayout.IntField ("Screen Height Resolution", myTarget.verticalResolution);
			break;
		}

		if (GUI.changed) 
			EditorUtility.SetDirty (target);
			
	}
}
