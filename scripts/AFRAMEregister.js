// 這一段註冊讓 AFRAME 的物件可以使用 look-at 來面向鏡頭
// https://stackoverflow.com/questions/66508949/a-frame-make-model-face-the-viewer-center-of-the-screen-or-canvas
AFRAME.registerComponent('look-at', {
    schema: { type: 'selector' },
    init: function () { },
    tick: function () {
        this.el.object3D.lookAt(this.data.object3D.position);
    }
});